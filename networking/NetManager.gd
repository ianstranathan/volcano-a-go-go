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
const INPUT_BUFFER_SIZE = 120 # Store 1 second of inputs
# id : Array[PlayerCommand]
var remote_input_buffers := {}

# ---------------------------------------------------------- other stuff to tick
var game_world: Node2D

# ----------------------------------------------------------------- ticking vars
var current_tick: int = 0     # -- each machines tick number for state reconcile
var _timer: float = 0.0       # -- just counting up delta for tick increment
const TICK_RATE := 1.0 / 60.0 # -- tick rate have to be deterministic
var fract_tick: float = 0.0   # -- decimal remainder of the tick
var update_remote_modulo : int = 2 # -- e.g. 60hz -> 30hz
var clock_synced := false
const ideal_tick_lead := 12

# -------------------------------------------------------------- tick multiplier
const min_num_future_commands := 2
const max_num_future_commands := 15
# -- for normalizing t in  time_multiplier()
const future_command_range = float(max_num_future_commands - min_num_future_commands)
var curr_num_future_commands := 8


# -----------------------------------------------------------------
var tick_scheduler := TickScheduler.new()

# -----------------------------------------------------------------
var local_player_name: String = "Unknown Player"
const KEY_NAME = "name"
const KEY_INDEX = "index"
const KEY_COLOR = "color"


# ---------------------------------------------------------- Debug UI
var last_host_tick: int = 0
var average_offset: float = ideal_tick_lead
var tick_error: int = 0
const OFFSET_LERP_WEIGHT := 0.05
const MAX_CLOCK_ADJUST := 0.02


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_client_connected_to_server)


# -- this is driving everything
func _physics_process(delta: float) -> void:
	# -- we shouldn't start until we're connected, I think this is one of
	# -- of the problems with the initial steam test
	if multiplayer.multiplayer_peer == null:
		return
	# -- we also don't want to start until clock is synced
	if !multiplayer.is_server() and !clock_synced:
		return
	# -- @Alex, this looks like it's doing a thing and then undoing
	# -- but we need to account for CPU fluxuations, and can't depend on the
	# -- implied 60hz, it has to be deterministic
	_timer += delta * tick_multiplier()
	while _timer >= TICK_RATE:
		current_tick += 1
		_timer -= TICK_RATE
		
		# -- this is the way we're implementing deterministic timers with our tick
		tick_scheduler.tick(current_tick)
		
		# -- this needs to go in game.execute_tick
		if game_world:
			game_world.execute_tick(TICK_RATE)
			
		for id in player_instances_by_player_id:
			var _player = player_instances_by_player_id[id]
			
			# -- are we the machine running this NetManager's instance? (host or client)
			if id == multiplayer.get_unique_id():
				# -- then step the local player's tick immediately (prediction)
				_player.player_controller.on_tick_generated(current_tick, TICK_RATE)
			# -- we need to run in lock step since packets can be lost
			# -- or become out of sync
			elif multiplayer.is_server():
				host_process_remote_client(id, _player)
			# -- host sends out RPC to give interpolation data to remote copies
			# -- and reconciliation data for client's local version
			if multiplayer.is_server() and (current_tick % update_remote_modulo == 0):
				sync_player_state.rpc(
						id,
						# -- current_tick - 1
						_player.player_controller.get_player_state( current_tick ).serialize()
					)
					#print("Host Broadcasting Tick: ", current_tick - 1, " for Player: ", id, " Pos: ", _player.global_position)
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


# ------------------------------------------ player state & command routing RPCs
# -- this is coming out at like 20-30hz
# -- this gives us a snapshot of the host's truth
# -- and we either reconcile or we interpolate
# -- ~~~~~~~~~
# -- Additionally, since we have a tick from host (host_versions_state.tick)
# -- we can measure a tick difference and slow or speed up accordingly
# -- current_tick - host_tick > ideal_lead ==> we're drifting into the future
# -- ==> we need to slow down
# -- current_tick - host_tick < ideal_lead ==> we need to speed up

@rpc("authority", "unreliable") 
func sync_player_state(id: int, byte_arr: PackedByteArray):
	var host_versions_state = PlayerState.deserialize( byte_arr )
	#update_tick_speed_multiplier( id, host_versions_state.tick)
	if !multiplayer.is_server() and !clock_synced:
	#if id == multiplayer.get_unique_id() and !multiplayer.is_server() and !clock_synced:
		# Check if the incoming tick is actually valid data
		if host_versions_state.tick > 0:
			clock_synced = true
			average_offset = ideal_tick_lead
			last_host_tick = host_versions_state.tick
			current_tick = host_versions_state.tick + ideal_tick_lead # -- RTT buffer
			return
	# ------------------------------------------ tracking tick offset per client
	if !multiplayer.is_server() and id == multiplayer.get_unique_id():
		# -- moving average
		last_host_tick = host_versions_state.tick
		var current_offset = current_tick - host_versions_state.tick
		average_offset = lerp(average_offset, float(current_offset), OFFSET_LERP_WEIGHT)

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

# -- Why discrete steps instead of a continuous lerp or something:
# -- Discrete steps act as a low-pass filter. They ignore the "vibration" of the network and only
# -- react when there is a sustained, significant trend of drifting too far away
func tick_multiplier() -> float:
	if multiplayer.is_server() or !clock_synced:
		return 1.0
	tick_error = average_offset - ideal_tick_lead
	# -- dead zone
	if abs(tick_error) < 0.5:
		return 1.0
	# -- average_offset is lerping toward current_offset
	# -- from above:
	# var current_offset = current_tick - host_versions_state.tick
	# average_offset = lerp(average_offset, float(current_offset), OFFSET_LERP_WEIGHT)
	
	var adjustment = clamp(tick_error * 0.01, -MAX_CLOCK_ADJUST, MAX_CLOCK_ADJUST)
	# -- 1. - adjust => account for sign
	# -- tick_error < 0 => that we're less than ideal tick lead and need to speed up
	# -- tick_error > 0 => that we're greater than ideal tick lead and need to slow down
	return 1.0 - adjustment

#func tick_multiplier() -> float:
	## curr_num_future_commands is mutated in host_process_remote_client
	#var n = clamp(curr_num_future_commands, min_num_future_commands, max_num_future_commands)
	#var t = float( max_num_future_commands - n ) / future_command_range
	## -- so, t is 0 when curr_num_future_commands == max_num_future_commands
	## -- and 1 when curr_num_future_commands == min_num_future_commands
	## -- so it's actually backwards:
	##2 is too few (Slow down the simulation of this player (95% speed) to let more packets arrive),
	##15 is too many (Speed up (105%) to catch up to the player's real-time position.
	#return lerp(1.05, 0.95, t)


# ------------------------------------------------------------------------------

# -- the client has to live in the "future" because of round trip time / jitter etc
# -- the host needs a way of getting data and then calling them at the approritate tick
func host_process_remote_client(id: int, _player: Player):
	if not remote_input_buffers.has(id):
		setup_remote_buffer(id)
	
	var buffer = remote_input_buffers.get(id)
	#print("we're in here")
	if buffer == null:
		return

	var idx = current_tick % INPUT_BUFFER_SIZE
	var cmd = buffer[idx]
	
	if cmd.tick == current_tick: # -- reconciliation
		_player.execute_tick(TICK_RATE, cmd)
		_player.player_controller.reconciliation_state_buffer[idx].set_state(_player, current_tick)
	else: # -- extraploation
		_player.execute_tick(TICK_RATE, _player.player_controller.last_command_executed)
		
		#_player.player_controller.reconciliation_state_buffer[idx].set_state(_player, current_tick)
		


#@rpc("any_peer", "unreliable")
#func send_input_to_host(byte_arr: PackedByteArray) -> void:
	#if not multiplayer.is_server():
		#return
	#var sender_id = multiplayer.get_remote_sender_id()
	#var cmd = PlayerCommand.deserialize(byte_arr)
	#
	## -- safety check
	#if remote_input_buffers.has(sender_id):
		#var idx = cmd.tick % INPUT_BUFFER_SIZE
		#remote_input_buffers[sender_id][idx] = cmd

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
