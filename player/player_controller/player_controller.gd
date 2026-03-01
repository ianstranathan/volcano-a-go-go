extends Node2D
class_name PlayerController


"""
Local: run command immediately, sends command to the host via rpc_id(1, args)
Host: Receives command, runs it on their version the player

Host broadcasts their remote copies state (See _physics_process in  NetManager) 
to everyone else at a lower hz

When a client recieves this broadcast (see sync_player_state in NetManager )
it either updates the remote data (See update_remote_state in this script )
if it's a remote copy (doesn't have authority)
Or it reconciles the state (checks to make sure the position, velocity, and
state variables agree to within a certain margin)
"""

@onready var player: Player = get_parent()
# -- either RemotePlayerController or LocalPlayerController
var controller: Node2D

# -- so we're keeping 60 ticks, or 1 second a 60hz physics sim
var input_and_state_buffer_size: int = 60
var command_history_buffer: Array[PlayerCommand] = []
var reconciliation_state_buffer: Array[PlayerState] = []

# -- 
var interpolation_buffer: Array[PlayerState] = []
var interpolation_buffer_size: int = 20

# -- 
var last_confirmed_tick: int = -1

# -- NOTE
# -- This requires the spawning logic to give authority to a node before
# -- that node enters the scene tree
func _ready() -> void:
	# -- if we're a local player, we're going to be predicting & reconciling
	if is_multiplayer_authority():
		controller = LocalPlayerController.new()
	# if we're a remote copy, we're going to be interpolating
	else:
		controller = RemotePlayerController.new()
	
	# -- for now, let's just put them on everybody, but I think I can cut this out
	command_history_buffer.resize( input_and_state_buffer_size )
	reconciliation_state_buffer.resize( input_and_state_buffer_size )
	interpolation_buffer.resize( interpolation_buffer_size )
	
	# -- initialize the circular buffers
	for i in range(input_and_state_buffer_size):
		command_history_buffer[i] = PlayerCommand.new()
		reconciliation_state_buffer[i] = PlayerState.new()
		if i < interpolation_buffer_size:
			interpolation_buffer[i] = PlayerState.new()
	
	# -- 
	add_child(controller)


func get_player_state( a_tick: int) -> PlayerState:
	return reconciliation_state_buffer[ get_circular_index( a_tick ) ]


func get_circular_index( a_tick: int) -> int:
	return a_tick % input_and_state_buffer_size


func update_remote_state(host_state: PlayerState):
	#print("Client received state for: ", host_state.tick, " Buffer size: ", interpolation_buffer.size())
	var incoming_tick = host_state.tick
	if incoming_tick <= 0:
		# -- ignore, chose -1 as intialization value
		return
	
	var _i = incoming_tick % interpolation_buffer_size
	interpolation_buffer[_i] = host_state
	#var incoming_tick = host_state.tick

	# -- Keep track of the tick?
	if incoming_tick > last_confirmed_tick:
		last_confirmed_tick = incoming_tick


#func _physics_process(delta):
	## -- locally we're predicting (immediately moving) & saving input + state
	#if is_multiplayer_authority():
		#var _tick = NetManager.current_tick
		#var _index = get_circular_index( _tick )
		## -- save command and state
		#var current_command = command_history_buffer[_index]
		#current_command.tick = _tick                     # -- timestamp the command
		#controller.update_command(current_command, delta)# -- update the command
		## -- save current state before you mutate it
		#reconciliation_state_buffer[_index].set_state( player, _tick )
		## -- immediately move the local player, i.e. prediction
		#player.apply_command(current_command)
		#
		## -- no need to rpc if this is the host (host is the truth afterall)
		#if !multiplayer.is_server():
			## -- send the command to the host for it to move its remote copies
			## -- and tell the other players that this player moved
			#NetManager.send_input_to_host.rpc_id(1, current_command.serialize())


var min_offset: float = 6.0    # Best case (100ms)
var max_offset: float = 15.0   # Worst case (~250ms)
var current_offset: float = 8.0 # Start in the middle
var shortage_frames: int = 0   # How many frames have we lacked a point_b?

func _process(delta):
	if is_multiplayer_authority(): 
		return

	var render_tick = (NetManager.current_tick + NetManager.fract_tick) - current_offset
	#print("Client render_tick: ", render_tick, " Buffer has: ", interpolation_buffer.map(func(d): return d.tick))
	var point_a: PlayerState = null
	var point_b: PlayerState = null

	# ----------------------------------------------- first, going over whole buffer
	# -- need two points on either side of our render interpolant
	#for data in interpolation_buffer:
		#if data.tick == -1:
			## -- -1 is an initialization choice, so this is just skipping frames
			## -- that never took data
			#continue
		#
		#if data.tick <= render_tick:
			#if point_a == null or data.tick > point_a.tick:
				#point_a = data
		#else: # data.tick > render_tick
			#if point_b == null or data.tick < point_b.tick:
				#point_b = data
	
	# ----------------------------------------------- OPTIMIZING walking backwards
	for i in range(interpolation_buffer_size):
		var check_tick = last_confirmed_tick - i
		var data = interpolation_buffer[check_tick % interpolation_buffer_size]
		
		if data == null or data.tick == -1:
			continue

		if data.tick <= render_tick:
			point_a = data
			# Since we are walking backwards, the very first tick <= render_tick 
			# we find is guaranteed to be the right one
			break 
		else:
			point_b = data # This was > render_tick, so it's a candidate for point_b

	# # -----------------------------------------------
	# -- interpolate position
	if point_a and point_b:
		# -- slowly lerp towards the min offset
		current_offset = lerp(current_offset, min_offset, 0.1 * delta)
		# -- this is just normalizing (0, 1) t
		var t = (render_tick - point_a.tick) / float(point_b.tick - point_a.tick)
		player.global_position = point_a.pos.lerp(point_b.pos, clamp(t, 0.0, 1.0))
	elif point_a:
		current_offset = min(current_offset + 0.2, max_offset)
		# -- do something if there's a bunch of shortage frames maybe?
		# shortage_frames += 1
		# we don't have enough data to interpolate => stay at the most recent packet
		player.global_position = point_a.pos


# -- TODO, check args using delta

# -- Called from netmanager on a local controller
# -- this allows a deterministic delta time (NetManager's TICK_RATE)
func on_tick_generated(tick: int, delta: float):
	# -- we don't need to check is_multiplayer_authority as this is
	# -- already being done from NetManager checking IDs
	
	# -- this is being called from NetManager, so no need to make a function call
	# -- or accessor back to NetManager
	var _index = get_circular_index(tick)

	# -- save command and state
	var current_command = command_history_buffer[_index]
	current_command.tick = tick                       # -- timestamp the command
	controller.update_command(current_command, delta) # -- update the command

	# -- save current state before applying it (slice of command and associated state)
	reconciliation_state_buffer[_index].set_state( player, tick )

	# -- immediately move the local player, i.e. prediction
	player.execute_tick(delta, current_command)

	# -- no need to rpc if this is the host (host is the truth afterall)
	if !multiplayer.is_server():
		#print("Client sending state for: ", current_command.tick)
		# -- send the command to the host for it to move its remote copies
		# -- and tell the other players that this player moved
		NetManager.send_input_to_host.rpc_id(1, current_command.serialize())


func reconcile(_host_state: PlayerState):
	pass
	#if pos_error > 3.0:
		#player.global_position = host_state.pos
		#player.velocity = host_state.velocity # Crucial for your Verlet integration!
		#
		#var replay_tick = host_state.tick + 1
		#while replay_tick <= NetManager.current_tick:
			#var idx = get_circular_index(replay_tick)
			## Re-simulate using the constant TICK_RATE delta
			#player.execute_tick(NetManager.TICK_RATE, command_history_buffer[idx])
			## Update the buffer so future reconciliations are accurate
			#reconciliation_state_buffer[idx].set_state(player, replay_tick)
			#replay_tick += 1
