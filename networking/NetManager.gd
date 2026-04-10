extends Node

"""
"""

# ------------------------------------------------------------ signals for lobby
signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal player_info_updated(id: int, player_name: String, spawn_index: int)

# -----------------------------------------------------------------
var player_instances_by_player_id  := {}
var player_data := {} 
const INPUT_BUFFER_SIZE = 240 # Store 4 seconds of inputs
var remote_input_buffers := {} # -- future command buffers per client

# ---------------------------------------------------------- other stuff to tick
var game_world: Node2D

# ----------------------------------------------------------------- ticking vars
var is_initialized := false
var current_tick: int = 0     # -- each machines tick number for state reconcile
var _timer: float = 0.0       # -- just counting up delta for tick increment
const TICK_RATE := 1.0 / 60.0 # -- tick rate have to be deterministic
var fract_tick: float = 0.0   # -- decimal remainder of the tick
var update_remote_modulo : int = 2 # -- e.g. 60hz -> 30hz
var clock_synced := false
var ideal_tick_lead: int = 0 # -- from initial ping, then dynamically updated
var last_host_tick: int = 0
var average_offset: float = 0
const OFFSET_LERP_WEIGHT := 0.05
const MAX_CLOCK_ADJUST := 0.02
# ------------------------------------------------------------------------------
var tick_scheduler := TickScheduler.new()

# ------------------------------------------------------------------------------
var local_player_name: String = "Unknown Player"
const KEY_NAME = "name"
const KEY_INDEX = "index"
const KEY_COLOR = "color"

# ------------------------------------------------------------------------------
var drift_history: Array[float] = []
const DRIFT_WINDOW_SIZE = 21          # Odd number for exact median
const median_index = 11

var pings: Array[float] = []
var ping_samples_needed: int = 10
# ------------------------------------------------------------------------------

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_client_connected_to_server)



func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	
	if !is_initialized:
		if multiplayer.is_server():
			# Server might need a different condition, 
			# e.g., waiting for at least one client or a 'start' signal
			pass 
		else:
			return # Clients wait for RTT and Clock Sync
	
	if !multiplayer.is_server() and !clock_synced:
		return

	_timer += delta * tick_multiplier()
	while _timer >= TICK_RATE:
		current_tick += 1
		_timer -= TICK_RATE
		
		# ----------------------------------------------------------------------
		tick_scheduler.tick(current_tick)
		
		# ---------------------------------------------------- game world update
		if game_world:
			game_world.execute_tick(TICK_RATE)
		
		# ------------------------------------------------------- players update
		for id in player_instances_by_player_id:
			var _player = player_instances_by_player_id[id]
			
			# -- are we the machine running this NetManager's instance? 
			# -- (host or client)
			if id == multiplayer.get_unique_id():
				# -- then step the local player's tick immediately (prediction)
				# -- this is sent to the server's client keyed buffer of 
				# -- tick-marked / saved commands
				_player.player_controller.on_tick_generated(current_tick, TICK_RATE)
			# -- go through of buffer of tick-marked / saved local player commands
			elif multiplayer.is_server():
				host_process_remote_client(id, _player)
			# -- at a slower Hz, host sends out RPC to give interpolation and
			# -- reconciliation data for client's local version
			if multiplayer.is_server() and (current_tick % update_remote_modulo == 0):
				sync_player_state.rpc(
						id,
						_player.player_controller.get_player_state( current_tick ).serialize()
					)
	# -- this is used for smoothly moving remote copies
	fract_tick = _timer / TICK_RATE


func create_player_entry(p_name: String, p_index: int) -> Dictionary:
	return {
		KEY_NAME: p_name,
		KEY_INDEX: p_index,
		KEY_COLOR: Color.WHITE # Default
	}


func _on_client_connected_to_server() -> void:
	var my_id = multiplayer.get_unique_id()
	player_data[my_id] = create_player_entry(local_player_name, -1)
	_update_player_name.rpc_id(1, local_player_name)


func leave() -> void:
	player_data.clear()


func setup_remote_buffer(id: int):
	var buffer: Array[PlayerCommand] = []
	buffer.resize(INPUT_BUFFER_SIZE)
	# -- prefill with empty commands to avoid null checks
	for i in range(INPUT_BUFFER_SIZE):
		buffer[i] = PlayerCommand.new()
	remote_input_buffers[id] = buffer


# Called on server when a new peer connects
func _on_peer_connected(new_player_id: int) -> void:
	# -- tell whoever is listening (i.e. a lobby)
	peer_connected.emit( new_player_id )

	if multiplayer.is_server():		
		# -- Send the new peer all the already existing players
		for id in player_data :
			setup_remote_buffer( id )
			var d = player_data[ id ]
			_register_player.rpc_id(new_player_id, id, d[KEY_NAME], d[KEY_INDEX])
	else:
		start_network_ping()

func _on_peer_disconnected(id: int) -> void:
	# -- tell whoever is listening (i.e. some way to catch the player leaving)
	peer_disconnected.emit(id)
	player_data.erase(id)


@rpc("any_peer", "reliable")
func _update_player_name(player_name: String) -> void:
	# -- only do this on the host
	if not multiplayer.is_server():
		return
	# Host calculates index ONCE
	
	# -- get id whoever is caling this for dict lookup
	# -- we accept the client's truth for its name (player_name)
	# -- we don't trust the client's truth for its id => get_remote_sender_id
	var sender_id = multiplayer.get_remote_sender_id()
	var spawn_index = player_data.size() 
	player_data[sender_id] = create_player_entry(player_name, spawn_index)
	# Broadcast updated name to all clients
	#var total_players = player_names_by_player_id.size()
	#var spawn_index = (total_players - 1)
	_register_player.rpc(sender_id, player_name, spawn_index)


# RPC: Server -> To All Clients
@rpc("authority", "call_local", "reliable")
func _register_player(id: int, p_name: String, s_index: int) -> void:
	# Everyone saves the server's dictated data
	player_data[id] = create_player_entry(p_name, s_index)
	player_info_updated.emit(id, p_name, s_index)


# -- let the game actually tell you the lookup reference
# -- i.e. game injects this when player is spawned
func register_player_instance(peer_id: int, player: Player) -> void:
	player_instances_by_player_id[peer_id] = player


func unregister_player(peer_id: int) -> void:
	player_instances_by_player_id.erase(peer_id)


# ------------------------------------------------------------ state syncing fns
func initialize_state_sync(host_versions_state_tick: int):
	clock_synced = true
	average_offset = float(ideal_tick_lead)
	drift_history.fill(ideal_tick_lead)
	last_host_tick = host_versions_state_tick
	current_tick = host_versions_state_tick + ideal_tick_lead # -- RTT buffer
	_timer = 0.0


@rpc("authority", "unreliable") 
func sync_player_state(id: int, byte_arr: PackedByteArray):
	var host_versions_state = PlayerState.deserialize( byte_arr )
	
	# -- rpcs by default go to everyone but the caller
	# -- authority additionally guards against non-authority player nodes from
	# -- using this function
	# -- this implies that all checks are unecessary here of the form:
	# ------ multiplayer.is_server() &
	# ------ id == multiplayer.get_unique_id()
  
	# ------------------------------------------------------------- initial sync
	#if (!multiplayer.is_server() and !clock_synced and 
		#ideal_tick_lead != null and host_versions_state.tick > 0):
		#initialize_state_sync(host_versions_state.tick)
	if !clock_synced and (ideal_tick_lead != 0) and host_versions_state.tick > 0:
		initialize_state_sync(host_versions_state.tick)
	
	# ---------------------------------------------------- tick drift per client
	#if !multiplayer.is_server() and id == multiplayer.get_unique_id():
	# -- moving average
	update_average_offset(host_versions_state.tick)
	last_host_tick = host_versions_state.tick
	
	# ----------------------------------------- interpolation and reconciliation
	var _player = player_instances_by_player_id.get(id)
	if !_player:
		return
	else:
		if id == multiplayer.get_unique_id():
			_player.player_controller.reconcile( host_versions_state )               
		else:
			# -- we just tell the client to save this state, the interpolation
			# -- happens on the local machine
			_player.player_controller.update_remote_state( host_versions_state )
	


func get_median_drift(_tick: int, new_sample:float) -> float:
	if drift_history.size() == 0:
		drift_history.resize(DRIFT_WINDOW_SIZE)
	var _idx = _tick % DRIFT_WINDOW_SIZE
	drift_history[_idx] = new_sample
	var sorted = drift_history.duplicate()
	sorted.sort()
	return sorted[median_index]


func update_average_offset(host_tick: int):
	var raw_offset = float(current_tick - host_tick)
	var filtered_offset = get_median_drift(host_tick, raw_offset)
	average_offset = lerp(average_offset, filtered_offset, OFFSET_LERP_WEIGHT)


func tick_error() -> float:
	return average_offset - ideal_tick_lead


# -- Why discrete steps instead of a continuous lerp or something:
# -- Discrete steps act as a low-pass filter. They ignore the "vibration" of the network and only
# -- react when there is a sustained, significant trend of drifting too far away
func tick_multiplier() -> float:
	if multiplayer.is_server() or !clock_synced:
		return 1.0
	var _tick_error = tick_error()
	if abs(_tick_error) < 0.5: 	# -- dead zone
		return 1.0
	var adjustment = clamp(_tick_error * 0.01, -MAX_CLOCK_ADJUST, MAX_CLOCK_ADJUST)
	# -- tick_error < 0 => that we're less than ideal tick lead and need to speed up
	# -- tick_error > 0 => that we're greater than ideal tick lead and need to slow down
	# -- 1. - adjust    => account for sign
	return 1.0 - adjustment


# -- the client has to live in the "future" because of round trip time / jitter etc
# -- the host needs a way of getting data and then calling them at the approritate tick
func host_process_remote_client(id: int, _player: Player):
	if not remote_input_buffers.has(id):
		setup_remote_buffer(id)
		return
		
	var buffer = remote_input_buffers.get(id)
	if buffer == null:
		return

	# -- update the hosts remote version of everyone
	# -- previous saved command from send_input_to_host
	var cmd = buffer[current_tick % INPUT_BUFFER_SIZE]
	# -- we just tick it off if it matches
	if cmd.tick > 0:
		if cmd.tick == current_tick:
			_player.execute_tick(TICK_RATE, cmd)
		else: # -- extraploation
			print("Player extraolating, tick:", current_tick)
			_player.execute_tick(TICK_RATE,
								_player.player_controller.last_command_executed)
		var _idx = _player.player_controller.get_circular_index( current_tick )
		_player.player_controller.reconciliation_state_buffer[_idx].set_state(_player, current_tick)



@rpc("any_peer", "unreliable")
func send_input_to_host(byte_arr: PackedByteArray) -> void:
	if not multiplayer.is_server(): 
		return
	var sender_id = multiplayer.get_remote_sender_id()
	var incoming_cmds = PlayerCommand.deserialize_list_of_commands(byte_arr) 

	if remote_input_buffers.has(sender_id):
		var buffer = remote_input_buffers[sender_id]
		for cmd in incoming_cmds:
			var idx = cmd.tick % INPUT_BUFFER_SIZE
			# -- overwrite if the data is actually newer than what is 
			# -- currently in that buffer slot.
			if buffer[idx].tick < cmd.tick:
				buffer[idx] = cmd

# -- see pickup.gd
# -- only copy on the host's machine can trigger the pickup
@rpc("authority", "call_local", "reliable")
func sync_item_pickup(a_world_id:int, a_peer_id: int, item_lookup_enum: ItemsDb.ItemNames):
	# -- we want to tell the other players that this pickup exists
	Events.item_picked_up.emit( a_world_id ) # -- what used to be a callback to delete the pickup
	var _player = player_instances_by_player_id[ a_peer_id ]
	if _player:
		#print("Picking up from id: ", multiplayer.get_unique_id())
		_player.get_node("ItemManager").pick_up(item_lookup_enum)



# ------------------------------------------------------------ initial ping test
# ------------------------------------------------------------ for RRT value
func start_network_ping():
	pings.clear()
	_send_ping()


func _send_ping():
	var send_time = Time.get_ticks_msec()
	host_acknowledge_ping.rpc_id(1, send_time)


@rpc("any_peer", "reliable")
func host_acknowledge_ping(client_send_time: int):
	if multiplayer.is_server():
		client_receive_pong.rpc_id(multiplayer.get_remote_sender_id(), client_send_time)


@rpc("authority", "reliable")
func client_receive_pong(original_send_time: int):
	var arrival_time = Time.get_ticks_msec()
	var current_rtt = arrival_time - original_send_time
	pings.append(current_rtt)

	if pings.size() < ping_samples_needed:
		# Wait a tiny bit and ping again
		await get_tree().create_timer(0.1).timeout
		_send_ping()
	else:
		ideal_tick_lead = _calculate_final_offset()
		is_initialized = true


func _calculate_final_offset() -> int:
	var rtt = pings.reduce( func(acc, x): return acc + x, 0) / pings.size()
	var one_way_latency = (rtt / 2.0) / 1000.0 # -- msec -> sec
	# -- sec -> ticks
	# -- 1 / 60 
	var one_way_latency_in_ticks = ceil(one_way_latency / TICK_RATE) + 2 # +2 for safety/jitter
	print("Initial Ping with RTT: ", rtt, "ms. Recommended Tick Offset: ", one_way_latency_in_ticks)
	return one_way_latency_in_ticks
