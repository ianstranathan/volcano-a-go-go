extends Node2D
class_name PlayerController


"""
Local: run command immediately, sends command to the host via rpc_id(1, args)
Host: Receives command, runs it on their version the player

Host broadcasts their remote copies state (See _physics_process in  NetManager) 
to everyone else at a lower hz

When a client recieves this broadcast (see sync_player_state in NetManager )
it either updates the remote data (See update_remote_state in this script )
if it's a remote copy
Or it reconciles the state (checks to make sure the position, velocity, and
state variables agree to within a certain margin)
"""

@onready var TICK_RATE = NetManager.TICK_RATE
@onready var player: Player = get_parent()
# -- either RemotePlayerController or LocalPlayerController
var controller: LocalPlayerController

# -- so we're keeping 60 ticks, or 1 second a 60hz physics sim
var input_and_state_buffer_size: int = 240
var command_history_buffer: Array[PlayerCommand] = []
var reconciliation_state_buffer: Array[PlayerState] = []

# -- 
var interpolation_buffer: Array[PlayerState] = []
var interpolation_buffer_size: int = 20

# -- 
var last_command_executed: PlayerCommand = PlayerCommand.new()
var last_confirmed_interpolation_tick: int = -1
var last_confirmed_reconcilliation_tick: int = -1

var recent_cmds: Array[PlayerCommand] = []
var recent_cmd_range := 5 # -- we're sending 5 commands or 105 bytes to host every tick

# -- NOTE
# -- This requires the spawning logic to give authority to a node before
# -- that node enters the scene tree
func _ready() -> void:
	# -- if we're a local player, we're going to be predicting & reconciling
	if is_multiplayer_authority():
		controller = LocalPlayerController.new()
		add_child(controller)
		
	# -- for now, let's just put them on everybody, but I think I can cut this out
	command_history_buffer.resize( input_and_state_buffer_size )
	reconciliation_state_buffer.resize( input_and_state_buffer_size )
	interpolation_buffer.resize( interpolation_buffer_size )
	recent_cmds.resize(recent_cmd_range)
	
	reset_all_buffers()
	# -- initialize the circular buffers
	#for i in range(input_and_state_buffer_size):
		#command_history_buffer[i] = PlayerCommand.new()
		#reconciliation_state_buffer[i] = PlayerState.new()
		#
		## -- size recent cmd buffer
		#if i < recent_cmd_range:
			#recent_cmds[i] = PlayerCommand.new()
		#if i < interpolation_buffer_size:
			#interpolation_buffer[i] = PlayerState.new()


func reset_all_buffers():
	for i in range(input_and_state_buffer_size):
		command_history_buffer[i] = PlayerCommand.new()
		reconciliation_state_buffer[i] = PlayerState.new()
		
		# -- size recent cmd buffer
		if i < recent_cmd_range:
			recent_cmds[i] = PlayerCommand.new()
		if i < interpolation_buffer_size:
			interpolation_buffer[i] = PlayerState.new()


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
	interpolation_buffer[incoming_tick % interpolation_buffer_size] = host_state

	# -- Keep track of the tick?
	if incoming_tick > last_confirmed_interpolation_tick:
		last_confirmed_interpolation_tick = incoming_tick


# -- TODO, check args using delta
# -- Called from netmanager on a local controller
# -- this allows a deterministic delta time (NetManager's TICK_RATE)
func on_tick_generated(tick: int, delta: float):
	# -- we don't need to check is_multiplayer_authority as this is
	# -- already being done from NetManager checking IDs
	
	# -- this is being called from NetManager, so no need to make a function call
	# -- or accessor back to NetManager
	var _index = get_circular_index(tick)
	# ----------------------------------------------------- record cmd and state
	var current_command = command_history_buffer[_index]
	current_command.tick = tick                       # -- timestamp the command
	controller.update_command(current_command, delta) # -- update the command

	player.execute_tick(delta, current_command) # -- client prediction
	last_command_executed = current_command
	reconciliation_state_buffer[_index].set_state( player, tick )

	# -- no need to rpc if this is the host (host is the truth afterall)
	if !multiplayer.is_server():
		for i in range(recent_cmd_range):
			# -- get last N commands from existing command history
			var check_tick = tick - i # i is zero we're at tick, i is -5, we're 5 cmds back
			if check_tick > 0: # -- only do this if it's a valid tick
				# -- is this actually aligned to tick modulo?
				#var _idx = check_tick % recent_cmd_range
				#recent_cmds[_idx] = command_history_buffer[get_circular_index(check_tick)]
				recent_cmds[i] = command_history_buffer[get_circular_index(check_tick)]
		#print("Client sending state for: ", current_command.tick)
		# -- send the command to the host for it to move its remote copies
		# -- and tell the other players that this player moved
		#NetManager.send_input_to_host.rpc_id(1, current_command.serialize())
		NetManager.send_input_to_host.rpc_id(1, PlayerCommand.serialize_list_of_commands(recent_cmds))


# -- TODO
var min_offset: float = 6.0    # 100ms
var max_offset: float = 15.0   # ~250ms
var current_offset: float = 6.0 
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
		var check_tick = last_confirmed_interpolation_tick - i
		var data = interpolation_buffer[check_tick % interpolation_buffer_size]
		
		# -- skipping over missed frames
		if data == null or data.tick == -1:
			continue
		
		if data.tick <= render_tick:
			point_a = data
			# Since we are walking backwards, the very first tick <= render_tick 
			# we find is guaranteed to be the right one
			#var next_data = interpolation_buffer[(check_tick + 1) % interpolation_buffer_size]
			#if next_data != null and next_data.tick > render_tick:
				#point_b = next_data
			break 
		else:
			point_b = data # This was > render_tick, so it's a candidate for point_b

	# # -----------------------------------------------
	# -- interpolate position
	player.pos_previous = player.global_position
	if point_a and point_b:
		# -- slowly lerp towards the min offset
		current_offset = lerp(current_offset, min_offset, 0.1 * delta)
		# -- this is just normalizing (0, 1) t
		var t = (render_tick - point_a.tick) / float(point_b.tick - point_a.tick)
		player.global_position = point_a.pos.lerp(point_b.pos, clamp(t, 0.0, 1.0))
		# -- movement transition won't go unless there's a state mismatch
		player.movement_state_transition_to( point_a.movement_state )
	elif point_a:
		current_offset = min(current_offset + 0.2, max_offset)
		# -- do something if there's a bunch of shortage frames maybe?
		# shortage_frames += 1
		# we don't have enough data to interpolate => stay at the most recent packet
		player.global_position = point_a.pos
	player.pos_current = player.global_position

# -- where should we put these consts?
const POS_TOLERANCE: float = 5.0 # in pixels
#const ROT_TOLERANCE: float = 0.06 # in radians (i.e. about 3.5 degrees)

func reconcile(host_state: PlayerState):
	#return
	# -- we don't care about reconciling to an uninitialized state
	if host_state.tick <= 0:
		return
	
	# -- maybe we dropped some frames and accidentally indexed into a past
	# -- state from our circular buffer
	if last_confirmed_reconcilliation_tick > host_state.tick:
		return
	last_confirmed_reconcilliation_tick = host_state.tick
	
	var past_idx = get_circular_index(host_state.tick)
	var stored_state = reconciliation_state_buffer[past_idx]
	
	# -- if we don't have it in the buffer, we can't do anything with it
	if stored_state.tick != host_state.tick:
		return
	
	var pos_error = stored_state.pos.distance_to(host_state.pos)
	#var rot_error = abs(angle_difference(stored_state.rot, host_state.rot))
	var needs_reconciled = (
		pos_error > POS_TOLERANCE 
		#rot_error > ROT_TOLERANCE or 
		#stored_state.movement_state != host_state.movement_state
	)

	# -- snap to the correct position in the past
	# -- and replay all the commands saved between this tick and the current tick
	if needs_reconciled:
		print("stored_state: ", stored_state.movement_state, "& hosts version's state:", host_state.movement_state)
		# -- correct the past record to authoritative host
		var copy_host_state = PlayerState.new()
		copy_host_state.copy_state(host_state)
		reconciliation_state_buffer[past_idx] = copy_host_state
		#stored_state.set_state(player, host_state.tick)
		
		# -- reset all the state variables to that moment
		player.global_position = host_state.pos
		player.velocity = host_state.vel
		player.rotation = host_state.rot
		player.movement_state = host_state.movement_state as Player.MovementStates


		# -- now we need to re-run all our commands starting after this tick
		var replay_tick = host_state.tick + 1
		# -- add a flag so sounds and other stuff don't play while reconciling
		player.is_replaying = true
		
		while replay_tick <= NetManager.current_tick:
			var r_idx = get_circular_index(replay_tick)
			var cmd = command_history_buffer[r_idx]

			# -- maybe we need to gaurd against accidentally getting a
			# -- time discontinuous command or non-monotonic-ish
			#if cmd.tick < replay_tick:
				#replay_tick += 1 # -- no infinite loops here friend
				#continue
			# -- we always do a thing then save it
			player.execute_tick(TICK_RATE, cmd)
			last_command_executed = cmd
			reconciliation_state_buffer[r_idx].set_state(player, replay_tick)

			replay_tick += 1
		
		player.is_replaying = false


#if stored_state.tick != host_state.tick or stored_state.tick == -1:
		#print("Reconcile check: Stored: ", stored_state.tick, " Host: ", host_state.tick)
		## -- small mismatch
		#if abs(stored_state.tick - host_state.tick) <= 15:
			## -- we are searching for a matching tick
			## -- outwardly from this tick, i.e. one tick less, one tick moree
			## -- then two ticks less and two ticks more...
			#var found = false
			#for i in range(1, 15):
				#for offset in [-i, i]:
					#var t = host_state.tick + offset
					#var idx = get_circular_index(t)
					#if reconciliation_state_buffer[idx].tick == t:
						#stored_state = reconciliation_state_buffer[idx]
						#found = true
						#break
				#if found:
					#break
			#if not found:
				#hard_reset(host_state)
				#return

#func hard_reset(host_state: PlayerState):
	#player.global_position = host_state.pos
	#player.velocity = host_state.vel
	#player.movement_state = host_state.movement_state as Player.MovementStates
	#NetManager.local_resync_to_host(host_state.tick)
	#reset_all_buffers()
	#last_command_executed = PlayerCommand.new()
	#last_confirmed_interpolation_tick = host_state.tick
	#reconciliation_state_buffer[get_circular_index(host_state.tick)].set_state(player, host_state.tick)
	#player.is_replaying = false
