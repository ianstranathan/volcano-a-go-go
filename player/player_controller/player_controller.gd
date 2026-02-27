extends Node2D
class_name PlayerController


"""
Local: Runs the logic immediately
Local: Sends Command to the host via rpc_id(1, args)
Host: Receives command, runs it on their "Server version" the player, 
and then broadcasts that everyone else.
"""

@onready var player: Player = get_parent()

# -- stuff to send over network that can get serialized
var current_command := PlayerCommand.new()
var current_player_state := PlayerState.new()

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
	if host_state.tick <= 0: 
		return # Ignore junk/init data
	#print("remote host updated with tick: ", host_state.tick, "and pos: ", host_state.pos)
	var _i = host_state.tick % interpolation_buffer_size
	interpolation_buffer[_i] = host_state
	var incoming_tick = host_state.tick

	# -- Keep track of the tick?
	#if incoming_tick > last_confirmed_tick:
		#last_confirmed_tick = incoming_tick


func _physics_process(delta):
	# -- local prediction
	if is_multiplayer_authority():
		var _tick = NetManager.current_tick
		var _index = get_circular_index( _tick )
		
		# -- save command and state
		var current_command = command_history_buffer[_index]
		current_command.tick = _tick                     # -- timestamp the command
		controller.update_command(current_command, delta)# -- update the command
		# -- save current state before you mutate it
		reconciliation_state_buffer[_index].set_state( player, _tick )
		# -- immediately move the local player, i.e. prediction
		player.apply_command(current_command)
		
		# -- no need to rpc if this is the host (host is the truth afterall)
		if !multiplayer.is_server():
			# -- send the command to the host for it to move its remote copies
			# -- and tell the other players that this player moved
			NetManager.send_input_to_host.rpc_id(1, current_command.serialize())


func _process(_delta):
	if is_multiplayer_authority(): 
		return

	var render_tick = (NetManager.current_tick + NetManager.fract_tick) - 10.0
	print("Client render_tick: ", render_tick, " Buffer has: ", interpolation_buffer.map(func(d): return d.tick))
	var point_a: PlayerState = null
	var point_b: PlayerState = null

	# -- need two points on either side of our render interpolant
	for data in interpolation_buffer:
		if data.tick == -1:
			# -- -1 is an initialization choice, so this is just skipping frames
			# -- that never took data
			continue
		
		if data.tick <= render_tick:
			if point_a == null or data.tick > point_a.tick:
				point_a = data
		else: # data.tick > render_tick
			if point_b == null or data.tick < point_b.tick:
				point_b = data
	
	# ----------------------------------------------- OPTIMIZING
	# -- walking backwards is more performant, but it's just stutter on 
	# -- the player.global_position = point_a.pos... so it's never getting enough
	# -- need two points on either side of our render_tick
	#var head_idx = last_confirmed_tick % interpolation_buffer_size

	# -- walk backwards starting from the latest received data
	#for i in range(interpolation_buffer_size):
		#var curr_idx = (head_idx - i + interpolation_buffer_size) % interpolation_buffer_size
		#var data = interpolation_buffer[curr_idx]
#
		#if data.tick == -1: 
			#continue
#
		## -- 
		#if data.tick <= render_tick:
			#point_a = data
			#break
		#else:
			#if point_b == null or data.tick < point_b.tick:
				#point_a = data
	#
	# -- interpolate position
	if point_a and point_b:
		var t = (render_tick - point_a.tick) / float(point_b.tick - point_a.tick)
		player.global_position = point_a.pos.lerp(point_b.pos, clamp(t, 0.0, 1.0))
	elif point_a:
		# we don't have enough data to interpolate => stay at the most recent packet
		player.global_position = point_a.pos
