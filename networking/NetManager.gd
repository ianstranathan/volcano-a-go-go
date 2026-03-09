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
const INPUT_BUFFER_SIZE = 60 # Store 1 second of inputs
# id : Array[PlayerCommand]
var remote_input_buffers := {}

# ----------------------------------------------------------------- ticking vars
var current_tick: int = 0     # -- each machines tick number for state reconcile
var _timer: float = 0.0       # -- just counting up delta for tick increment
const TICK_RATE := 1.0 / 60.0 # -- tick rate have to be deterministic
var fract_tick: float = 0.0   # -- decimal remainder of the tick
var update_remote_modulo : int = 2 # -- e.g. 60hz -> 30hz
var clock_synced := false


# -----------------------------------------------------------------
var local_player_name: String = "Unknown Player"
const KEY_NAME = "name"
const KEY_INDEX = "index"
const KEY_COLOR = "color"


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_client_connected_to_server)


# -- this is driving everything
func _physics_process(delta: float) -> void:
	# -- @Alex, this looks like it's doing a thing and then undoing
	# -- but we need to account for CPU fluxuations, and can't depend on the
	# -- implied 60hz, it has to be deterministic
	_timer += delta
	while _timer >= TICK_RATE:
		current_tick += 1
		_timer -= TICK_RATE
		
		# -- deterministic simulation rate
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
@rpc("authority", "unreliable") 
func sync_player_state(id: int, byte_arr: PackedByteArray):
	var host_versions_state = PlayerState.deserialize( byte_arr )
	if !multiplayer.is_server() and !clock_synced:
		# Check if the incoming tick is actually valid data
		if host_versions_state.tick > 0:
			clock_synced = true
			current_tick = host_versions_state.tick + 5.0
			#print("Client clock synced to Host tick: ", current_tick)
			return
	
	var _player = player_instances_by_player_id.get(id)
	if !_player:
		return
	else:
		if id == multiplayer.get_unique_id():
			#print("Host version's tick: ", host_versions_state.tick)
			_player.player_controller.reconcile( host_versions_state )               
		else:
			#print("Host version's tick: ", host_versions_state.tick)
			# -- interpolation
			# -- we just tell the client to save this state, the interpolation
			# -- happens on the local machine
			_player.player_controller.update_remote_state( host_versions_state )

# ------------------------------------------------------------------------------
# Outline of flow:
# local_player -> send_input_to_host ( -> host updates remote_input_buffers
# then
# in the hosts physics loop there is:
#	elif multiplayer.is_server():
#		host_process_remote_client(id, _player)
# so, this is just applying the remote version of a player on the hosts machine
# if it has a corresponding ticked packet
func host_process_remote_client(id: int, _player: Player):
	if not remote_input_buffers.has(id):
		setup_remote_buffer(id)
	
	var buffer = remote_input_buffers.get(id)
	#print("we're in here")
	if buffer == null:
		return

	var idx = current_tick % INPUT_BUFFER_SIZE
	var cmd = buffer[idx]
	
	if cmd.tick == current_tick:
		# -- what a bug...
		_player.player_controller.reconciliation_state_buffer[idx].set_state(_player, current_tick)
		_player.execute_tick(TICK_RATE, cmd)
	else:
		print("reconciliation fallback used")
		var fallback_cmd = PlayerCommand.new() 
		_player.execute_tick(TICK_RATE, fallback_cmd)


@rpc("any_peer", "unreliable")
func send_input_to_host(byte_arr: PackedByteArray) -> void:
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	var cmd = PlayerCommand.deserialize(byte_arr)
	
	# -- safety check
	if remote_input_buffers.has(sender_id):
		var idx = cmd.tick % INPUT_BUFFER_SIZE
		remote_input_buffers[sender_id][idx] = cmd

# -- see pickup.gd
# -- only a remote copy living on the host's machine can trigger the pickup
@rpc("authority", "call_local", "reliable")
func sync_item_pickup(a_world_id:int, a_peer_id: int, item_lookup_enum: ItemsDb.ItemNames):
	# -- we want to tell the other players that this pickup exists
	Events.item_picked_up.emit( a_world_id ) # -- what used to be a callback to delete the pickup
	var _player = player_instances_by_player_id[ a_peer_id ]
	if _player:
		#print(multiplayer.get_unique_id())
		_player.get_node("ItemManager").pick_up(item_lookup_enum)
