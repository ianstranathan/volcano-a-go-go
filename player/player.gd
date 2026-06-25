extends CharacterBody2D

class_name Player

# -- emitted from player_controller when reconcilliation happens for
# -- visual smoothing in the PlayerVisualInterpolator (sprite & item_manager)
signal reconciled
signal touched_bottom( peer_id: int)
signal dropped_pickup_item( item_key: ItemsDb.ItemNames, item_slot: int, pos: Vector2)

@export var kd: PlayerKinematicData
@onready var move_speed: float = kd.baseline_speed
@onready var current_accel = 0.0
@onready var g: float = kd.jump_gravity

# -- aliases of kinematic data for reference to player (e.g. items need this)
@onready var TERMINAL_FALL_SPEED = kd.TERMINAL_FALL_SPEED


# --------------------------------------------------------- ledge grabbing stuff
var target_ledge_grabbing_climb_pos: Vector2 = Vector2.ZERO
var ledge_grabbing_starting_player_pos
var is_ledge_climbing := false
var ledge_climb_progress := 0.0


# ----------------------------------------------------------- movement modifiers
var move_speed_modifier = 1.0
var jump_speed_modifier = 1.0
var gravity_modifier = 1.0
var hang_time_modifier = 1.0
## curve sample for jumping and falling state
## makes gravity less near peak of jump, see falling or jump state fn
@export var hang_time_curve: Curve

# -------------------------------------------------- Utils var for platforming
var current_platform = null # -- for calculating relative velocities
var move_input: Vector2 = Vector2.ZERO
var last_move_input: Vector2 = Vector2.ZERO
var last_wall_normal: Vector2 = Vector2.ZERO

# -------------------------------------------------- Buffer Timers
var coyote_timer: TickTimer            = TickTimer.new(0.15)
var jump_buffer_timer: TickTimer       = TickTimer.new(0.15)
var wall_jump_coyote_timer: TickTimer  = TickTimer.new(0.25)
var ledge_grab_buffer_timer: TickTimer = TickTimer.new(0.30)
#var side_somersault_timer: TickTimer   = TickTimer.new(0.25)


# -- The number of frames where you can't move horizontally after wall jump 
var manual_wall_jump_frame_counter: int = 0
@export var num_frame_you_cant_move_after_wall_jump :int = 6

# ------------------------------------------------------------------------- misc
var can_climb := false
# -- our "truth" about being on the ground (e.g. slightly off ledge)
var is_on_ground := true 


#@export var lava_ref: Node2D

var input_manager: LocalPlayerController
@onready var player_controller = $PlayerController
var is_replaying: bool = false


# --------------------------------------------------- state sprite effects stuff
var last_tocuhing_surface_state: MovementStates


enum MovementStates
{
	IDLE,
	WALKING,
	RUNNING,
	JUMPING,
	FALLING,
	CROUCHING,
	WALL_SLIDING,
	LEDGE_GRABBING,
	ITEM_MOVING,
	CLIMBING,
	CLOUD,
	PORTAL,
	SLIDING,
}
@export var movement_state: MovementStates = MovementStates.IDLE

@export_category("Scene Heirarchy Stuff")

# the dedicated container in the same scene depth as the player that holds item instances
#var items_container: Node2D

#------------------------------------------------------------------- sprite vars
var color: Color = Color(1., 1., 1., 1.);

var can_run: bool = true

func _ready() -> void:
	#----------------------------------------------------------- Running signals
	$StaminaVisual.stamina_depleted.connect( func(): 
		can_run = false)
	$StaminaVisual.stamina_started_recharging.connect( func(): 
		can_run = true)
	
	#---------------------------------------------------------------------------
	$Sprite2D.material.set_shader_parameter("src_col", color)
	$Sprite2D.material.set_shader_parameter("dummy_burn_timer", 5.0)
	
	$ClimbingInterface.climbing_area_entered.connect( func(): can_climb = true )
	$ClimbingInterface.climbing_area_exited.connect( func(): can_climb = false)
	#------------------------------------------------------- grabbable component
	#signal got_tossed( dir: Vector2)
	#signal got_grabbed( n: Node2D)
	#---------------------------------------------
	#assert(items_container)
	#$ItemManager.items_container = items_container
	
	#-------------------------------------------------- Local and remote signals
	#----------------------------- this controls items being able to move player
	# TODO this should only be valid on either host or local player
	# -- should have some kind of error that signal isn't connecting to anything on
	# -- remotes
	$ItemManager.item_moving_started.connect( func():
			movement_state_transition_to( MovementStates.ITEM_MOVING))
	$ItemManager.item_moving_stopped.connect( func():
			if is_falling():
				coyote_timer.start()
			else:
				movement_state_transition_to( MovementStates.IDLE))
	# ------------------------------------------------------------ Local signals
	if is_multiplayer_authority():
		# -- TODO get_child(0) is terrible
		input_manager = $PlayerController.get_child(0)
		#local_controller_added.emit( input_manager )
		assert($PlayerController.get_children().size() == 1)
		assert(input_manager is LocalPlayerController)
		var aiming_visual  = load("res://player/aiming_visual/aiming_visual.tscn").instantiate()
		add_child(aiming_visual)
		# -------------------------------------------- this controls aiming line
		input_manager.aim_input_detected.connect( func():
			aiming_visual.update_aiming_visual())
			
		
		# ------------------------------------------ this controls aiming target
		
		$ItemManager.item_targeted_something.connect( func(pos_or_null):
			aiming_visual.update_target_pos( pos_or_null))
		$ItemManager.item_ray_target_position_changed.connect( func(pos: Vector2):
			aiming_visual.update_dir( pos ))
			
		# --
		$ItemManager.item_switched.connect( func( keep_aiming_visual):
			if keep_aiming_visual:
				aiming_visual.start_aiming()
			else:
				aiming_visual.stop_aiming())
		#$ItemManager.targeting_item_added.connect( func():
			#aiming_visual.start_aiming( ))
		input_manager.inventory_slot_selected.connect( func(slot_index: int):
			$ItemManager.select_inventory_slot.rpc(slot_index))

	coyote_timer.timeout.connect( coyote_time_resolution)


enum JumpTypes
{
	REGULAR,
	SOMERSAULT_FLIP,
	WALL
}

func check_for_jump() -> void:
	if !jump_buffer_timer.is_stopped():
		if is_on_ground:
			is_on_ground = false
			#if !side_somersault_timer.is_stopped():
				#do_jump(JumpTypes.SOMERSAULT_FLIP)
			#else:
			do_jump(JumpTypes.REGULAR)
		elif can_wall_jump():
			move_input = Vector2(-last_wall_normal.x, move_input.y)
			manual_wall_jump_frame_counter = num_frame_you_cant_move_after_wall_jump
			wall_jump_coyote_timer.stop()
			do_jump(JumpTypes.WALL)
		elif is_ledge_grabbing():
			do_jump(JumpTypes.REGULAR)
		# NOTE change this man
		elif movement_state == MovementStates.CLIMBING:
			do_jump(JumpTypes.REGULAR)

#@onready var kd.wall_jump_scale: Vector2 = Vector2(kd.jump_speed / 2.0,
					 							#kd.jump_speed / 1.3)
func do_jump(jump_type, velocity_override=null):
	# -- logic of what to do for a specific jump
	jump_buffer_timer.stop()
	match jump_type:
		JumpTypes.REGULAR:
			velocity.y = kd.jump_speed
		#JumpTypes.SOMERSAULT_FLIP:
			#velocity.y = kd.jump_speed * jump_speed_modifier * somersault_factor
			#var tween = create_tween()
			#tween.tween_property(self, 
						#"global_rotation",
						#global_rotation + sign(last_move_input.x) * TAU, time_to_peak)
		JumpTypes.WALL:
			if !velocity_override:
				velocity = Vector2(-last_wall_normal.x * kd.wall_jump_scale.x,
									kd.wall_jump_scale.y)
			else:
				velocity = velocity_override
			# -- maybe want both components to be affected?

	velocity.y *= jump_speed_modifier

	movement_state_transition_to(MovementStates.JUMPING)
	if is_multiplayer_authority() and not is_replaying:
		Events.emit_signal("play_world_sound",
							AudioDb.WorldSoundId.JUMP,
							global_position,0,randf_range(0.8, 1.20),
							{})
	

func coyote_time_resolution() -> void:
	# the transition should only happen if we're coming from a certain set
	# of states, otherwise we'll jump in coyote time but be in falling state
	match movement_state:
		MovementStates.IDLE:
			movement_state_transition_to(MovementStates.FALLING)
		MovementStates.WALKING:
			movement_state_transition_to(MovementStates.FALLING)
		MovementStates.ITEM_MOVING:
			if is_falling():
				movement_state_transition_to(MovementStates.FALLING)
			else:
				movement_state_transition_to(MovementStates.IDLE)
	is_on_ground = false

# ------------------------------------------------------------------------------
var pending_impulses: Array[Vector2] = []

func apply_external_impulse(impulse: Vector2):
	pending_impulses.append( impulse )

# ------------------------------------------------------------------------------

# -- for itnerpolating sprite / visual smoothing in reconcilliation
var pos_previous: Vector2 = Vector2.ZERO
var pos_current: Vector2 = Vector2.ZERO
var last_collision_impulse := Vector2.ZERO
var last_collision_id: int = -1


func execute_tick(delta: float, cmd: PlayerCommand):
	if !is_replaying:
		for impulse in pending_impulses:
			velocity +=  kd.inv_mass * impulse
		pending_impulses.clear()
	if cmd.impulse != Vector2.ZERO:
		velocity += kd.inv_mass * cmd.impulse
	
	pos_previous = global_position
	apply_command(cmd)
	$ItemManager.process_item_tick(delta, cmd)
	
	if !last_move_input:
		last_move_input = move_input
	
	$StaminaVisual.update_tick( delta )
	
	# -- climbing check
	if should_start_climbing():
		start_climbing()
	
	# -- manual wall jumping frame management:
	if manual_wall_jump_frame_counter > 0:
		manual_wall_jump_frame_counter -= 1
	
	# -- call the movement state function matching the movement_state variable
	call(MovementStates.keys()[movement_state].to_lower() + "_state_fn", delta)

	if current_platform: # -- account for relative velocities
		#print(current_platform.get_velocity() * delta)
		velocity += current_platform.get_velocity() * delta
		move_and_collide(current_platform.get_velocity() * delta)

	# -- virtual collision check for player on player collisions
	#if !is_replaying and cmd.impulse == Vector2.ZERO:
		#var coll = move_and_collide(velocity * delta, true)
		#if coll:
			#var _collider := coll.get_collider()
			#if _collider and _collider is Player and !is_replaying:
				## -- locally predict collision for responsiveness
				#var impulse      = MyPhysicsUtils.resolve_collision(self, _collider, coll)
				#cmd.impulse      = impulse
				## -- cliuent A:
				## -- locally precict our impulse change
				#velocity += kd.inv_mass * impulse
				## -- client B:
				## -- locally predict remote interpolated client
				## -- by injecting into their interpolation buffer
				#_collider.player_controller.inject_predicted_state(
					#-_collider.kd.inv_mass * impulse
				#)
				## -- so we update our command for host processing client B
				## -- on hosts machine
				#var _id          = _collider.name.to_int() 
				#cmd.collided_id  = _id
				#
				## -- rpc the client we collided with to tell them to updat their impulse
				#predict_impact_notification.rpc_id(_collider.name.to_int(), impulse)
	
	global_position += (velocity * delta) + Vector2(0., (0.5 * delta * delta * get_g()))
	
	if velocity.y < kd.TERMINAL_FALL_SPEED:
		velocity.y += get_g() * delta

	var collision = move_and_collide(Vector2.ZERO)
	
	if collision:
		var normal = collision.get_normal()
		is_on_ground = normal.dot(Vector2.UP) > 0.7
		if is_on_ground:
			current_platform_check( collision )
			if velocity.y > 0:
				velocity.y = 0
				
	last_move_input = move_input
	pos_current = global_position

# ------------------------------------------------------------------------------

@rpc("any_peer", "unreliable")
func predict_impact_notification( impulse: Vector2):
	# -- locally predict on the client B now, -tive, equal but opposite
	velocity -= kd.inv_mass * impulse
	# -- update interpolated client A now
	var id = multiplayer.get_remote_sender_id()
	var caller = NetManager.player_instances_by_player_id.get( id )
	if caller:
		# -- it's +tive, equal but opposite
		caller.player_controller.inject_predicted_state(
			caller.kd.inv_mass * impulse
		)

# ------------------------------------------------------------------------------


# -- TODO
func current_platform_check(coll: KinematicCollision2D):
	var collider = coll.get_collider()
	if collider and collider.is_in_group("lava-bodies"):
		current_platform = collider


#@rpc("any_peer", "call_local", "reliable")
#func set_rel_velocity_platform( collider_id ):
	#pass


func my_is_on_floor() -> bool:
	# -- is any downward pointing ray colliding with something?
	# -- the built in "is_on_floor()" only works with move_and_slide
	return $FloorCheckContainer.get_children().reduce(func(accum, child):
		return (accum or child.is_colliding()), false)


func is_falling():
	return velocity.y >= 0 and not my_is_on_floor()


#@onready var rhs_ledge_grab_pair: Array[RayCast2D] = [$LedgeRayContainer/RHS, $WallCheckContainer/RHS1]
#@onready var lhs_ledge_grab_pair: Array[RayCast2D] = [$LedgeRayContainer/LHS, $WallCheckContainer/LHS1]
#@onready var ledge_grab_arrs = [rhs_ledge_grab_pair, lhs_ledge_grab_pair]


@onready var lhs_wall_rays:  Array[RayCast2D] = [
	$WallCheckContainer/LHS1,
	$WallCheckContainer/LHS2,
	$WallCheckContainer/LHS3
]
@onready var rhs_wall_rays:  Array[RayCast2D] = [
	$WallCheckContainer/RHS1,
	$WallCheckContainer/RHS2,
	$WallCheckContainer/RHS3
]

# -- NOTE
# -- this also sets a ledge grabbing position
# -- and a grabbing_climb_to position


func is_ledge_grabbing(_set_global_position=false) -> bool:
	var grabbing_left = last_move_input.x < 0
	var wall_arr := lhs_wall_rays if grabbing_left else rhs_wall_rays
	var top_down_ray := $TopDownRayContainer/LHS if grabbing_left else $TopDownRayContainer/RHS
	var ledge_ray := $LedgeRayContainer/LHS if grabbing_left else $LedgeRayContainer/RHS
	# -- if any of the wall rays are colliding and the ledge ray isn't colliding
	var ret = false
	var ledge_grab_position: Vector2

	for _ray in wall_arr:
		if _ray.is_colliding() and !ledge_ray.is_colliding() and top_down_ray.is_colliding():
			ret = true
			ledge_grab_position = Vector2(
				_ray.get_collision_point().x,
				top_down_ray.get_collision_point().y)
			# -- taget climb up should be the player just standing on the edge
			target_ledge_grabbing_climb_pos = (ledge_grab_position +
				Vector2(sign(last_move_input.x) * $CollisionShape2D.shape.radius,
						-0.5 * $CollisionShape2D.shape.height))
	if ret and _set_global_position:
		# -- magic number is to just make it look slightly more natural (we don't want the very top)
		# -- of the collshape to be at the ledge
		global_position.y = ledge_grab_position.y + 0.7 * $CollisionShape2D.shape.height / 2.

	return ret


func set_debug_label(new_movement_state: MovementStates) -> void:
	$Label.text = MovementStates.keys()[new_movement_state]


#------------------------------------------------- movement state fns
func move_resolution(move_speed_override=null):
	var target_speed
	if move_speed_override:
		target_speed = move_input.x * move_speed_override * move_speed_modifier
	else:
		target_speed = move_input.x * move_speed * move_speed_modifier
	var is_turning := move_input.x * velocity.x < 0
	var is_overspeed : bool = abs(velocity.x) > abs(target_speed)
	
	var target_accel_rate = kd.TURN_ACCL if is_turning else kd.MOV_ACCL
	current_accel = lerp(current_accel, float(target_accel_rate), 0.15)

	if is_overspeed and not is_turning:
		var _is_in_air = movement_state in [MovementStates.FALLING, MovementStates.JUMPING]
		var decl_weight = kd.AIR_DECL if _is_in_air else kd.DECL
		velocity.x = move_toward(velocity.x, 0, decl_weight)
	else:
		velocity.x = move_toward(velocity.x, target_speed, current_accel)


func stop_resolution():
	current_accel = move_toward(current_accel, kd.MOV_ACCL, kd.DECL)


var testing: bool = false
func move(move_func_override = null) -> void:
	if testing:
		return
	if move_func_override:
		move_func_override.call()
		return

	if manual_wall_jump_frame_counter > 0:
		return

	if not is_zero_approx(move_input.x):
		move_resolution()
	else:
		stop_resolution()


func check_for_falling() -> bool:
	return is_falling() and coyote_timer.is_stopped()


# -- consolidate the stuff that's always true on the ground
func idle_state_fn(_delta) -> void:
	check_for_jump()
	velocity.x = move_toward(velocity.x, 0.0, kd.MOV_ACCL)
	if !is_zero_approx(move_input.x):
		movement_state_transition_to( MovementStates.WALKING)
	if check_for_falling():
		coyote_timer.start()


func walking_state_fn(_delta) -> void:
	if is_zero_approx(move_input.x): #and side_somersault_timer.is_stopped():
		movement_state_transition_to( MovementStates.IDLE)
	check_for_jump()
	move()
	if check_for_falling():
		coyote_timer.start()


func running_state_fn( _delta) -> void:
	if is_zero_approx(move_input.x): #and side_somersault_timer.is_stopped():
		movement_state_transition_to( MovementStates.IDLE)
	check_for_jump()
	move_resolution( 1.8 * move_speed )
	if check_for_falling():
		coyote_timer.start()

# -- case: where we want a wall jump as fast as possible
func wall_jump_fast_utility():
	if !jump_buffer_timer.is_stopped():
		var _normal := wall_normal()
		if _normal != Vector2.ZERO:
			do_jump(JumpTypes.WALL,  kd.wall_jump_scale * Vector2(-_normal.x, 1.))


func jumping_state_fn(_delta) -> void:
	# -- be careful, I consciously took away an absolute value check
	# -- jumping should always be a negative direction
	hang_time_modifier = hang_time_curve.sample(1. - (velocity.y / kd.jump_speed))
	
	handle_corner_correction()
	move()
	wall_jump_fast_utility()
	if is_falling():
		movement_state_transition_to(MovementStates.FALLING)


# -- Climbing utils
func should_start_climbing():
	return (can_climb and move_input.y > 0.2 and movement_state != MovementStates.CLIMBING)


func start_climbing() -> void:
	velocity = Vector2.ZERO
	g = 0.0
	movement_state_transition_to(MovementStates.CLIMBING)


var climb_move_override: Callable = (func():
	var _inverted_y_move_input = Vector2(move_input.x, -move_input.y)
	velocity = velocity.move_toward(_inverted_y_move_input * kd.climb_speed * move_speed_modifier, kd.MOV_ACCL))


func climbing_state_fn(_delta):
	$ItemManager.stop_using_item()
	check_for_jump() # -- will change to jump state
	move( climb_move_override )
	if !can_climb:
		g = kd.fall_gravity
		movement_state_transition_to(MovementStates.FALLING)

# -- Utility functions to make platforming easier
# NOTE handle_platform_fall_near_miss_correction
#      &
#      handle_corner_correction
#      are the same up to a sign change (they do opposite nudging)
#      and the raycast container names => should probably consolidate

## nudges player in direction toward edge of platform if hitting from above, i.e falling
var nudge_to_edge_speed := 3.0 # in px
func handle_platform_fall_near_miss_correction():
	# -- should only run during fall state
	if ($FloorCheckContainer/LHS.is_colliding() and 
	   !$FloorCheckContainer/RHS.is_colliding()):
		# Move player right to clear the corner
		global_position.x -= nudge_to_edge_speed
	elif ($FloorCheckContainer/RHS.is_colliding() and 
		 !$FloorCheckContainer/LHS.is_colliding()):
		# Move player left to clear the corner
		global_position.x += nudge_to_edge_speed

## nudges player in direction toward edge of platform if hitting from below, i.e jumping
func handle_corner_correction():
	# -- should only run during jump state
	if velocity.y < 0: # Only while jumping up
		if ($CeilingCheckContainer/LHS.is_colliding() and 
		   !$CeilingCheckContainer/RHS.is_colliding()):
			# Move player right to clear the corner
			global_position.x += nudge_to_edge_speed
		elif ($CeilingCheckContainer/RHS.is_colliding() and 
			 !$CeilingCheckContainer/LHS.is_colliding()):
			# Move player left to clear the corner
			global_position.x -= nudge_to_edge_speed


func can_wall_slide():
	#var input = move_input
	var _wall_normal = wall_normal()
	last_wall_normal = _wall_normal
	var is_touching_wall = !_wall_normal.is_equal_approx(Vector2.ZERO)
	var is_pressing_into_wall = _wall_normal.x * move_input.x < 0
	return (is_touching_wall and is_pressing_into_wall and move_input.y > -0.65)


# -- TODO 
# -- abstract out repeating ledge grab check!
func falling_state_fn(_delta) -> void:
	# -- be carefule, I consciously took away an absolute value check
	# -- falling should always be positive direction
	hang_time_modifier = hang_time_curve.sample(velocity.y / kd.TERMINAL_FALL_SPEED)
	handle_platform_fall_near_miss_correction()
	# -- maybe we wanna go through the air slightly slower?
	
	move()
	wall_jump_fast_utility()
	
	# -- ledge climbing target position is mutated / saved in is_ledge_grabbing()
	if is_ledge_grabbing(true) and ledge_grab_buffer_timer.is_stopped():
		velocity = Vector2.ZERO
		g = 0
		start_ledge_grab()
	
	if !wall_jump_coyote_timer.is_stopped():
		check_for_jump()
	elif can_wall_slide():
		movement_state_transition_to(MovementStates.WALL_SLIDING)
	elif my_is_on_floor():
		movement_state_transition_to(MovementStates.IDLE)


func wall_normal() -> Vector2:	
	for ray in $WallCheckContainer.get_children():
		if ray.is_colliding():
			return ray.get_collision_normal()
	return Vector2.ZERO


# -- a buffered version of wall-sliding
func can_wall_jump():
	return (!last_wall_normal.is_equal_approx(Vector2.ZERO) and 
			!wall_jump_coyote_timer.is_stopped())


func wall_sliding_state_fn(_delta) -> void:
	if can_wall_slide():
		if wall_jump_coyote_timer.is_stopped():
			wall_jump_coyote_timer.start()
	else:
		movement_state_transition_to(MovementStates.FALLING)
	
	check_for_jump()
	
	if my_is_on_floor():
		movement_state_transition_to(MovementStates.IDLE)
	elif is_ledge_grabbing():
		velocity = Vector2.ZERO
		g = 0
		start_ledge_grab()

# -- probably move this elsewhere
func item_moving_state_fn(_delta) -> void:
	if $ItemManager.active_movement_override.allows_horizontal_movement():
		if !move_input.is_zero_approx():
			velocity.x = move_toward(velocity.x, move_input.x * move_speed * move_speed_modifier, kd.MOV_ACCL / 3.0)
		else:
			velocity.x = move_toward(velocity.x, 0.0, kd.DECL / 12.0)

	if $ItemManager.active_movement_override.allows_jump() and !jump_buffer_timer.is_stopped():
			$ItemManager.stop_using_item()
			velocity.y += kd.jump_speed * jump_speed_modifier
			movement_state_transition_to(MovementStates.JUMPING)
	if ($ItemManager.active_movement_override.allows_ledge_grab() and 
		is_ledge_grabbing() and 
		ledge_grab_buffer_timer.is_stopped()):
		# -- we stop gravity and falling velocity, save the climbing pos
		$ItemManager.stop_using_item()
		velocity = Vector2.ZERO
		g = 0
		start_ledge_grab()

	# -- does this allow me to remove fall check in parachute?
	if $ItemManager.active_movement_override.stops_on_floor() and my_is_on_floor():
		$ItemManager.stop_using_item()
		movement_state_transition_to(MovementStates.IDLE)
	if $ItemManager.active_movement_override.allows_rope_climb() and should_start_climbing():
		$ItemManager.stop_using_item()
		start_climbing()


func start_ledge_grab():
	is_ledge_climbing = false # -- the actual motion hasn't started yet
	if target_ledge_grabbing_climb_pos:
		ledge_climb_progress = 0.0
		movement_state_transition_to(MovementStates.LEDGE_GRABBING)
	else:
		movement_state_transition_to( MovementStates.FALLING)


func ledge_grabbing_state_fn(delta) -> void:
	check_for_jump()
	
	# -- start climbing if you press up and you can
	if move_input.y > 0.6 and !is_ledge_climbing:
		is_ledge_climbing = true
		$CollisionShape2D.set_deferred("disabled", true)
		ledge_grabbing_starting_player_pos = global_position
	
	if is_ledge_climbing:
		ledge_climb_progress += 4. * delta
		global_position = ledge_grabbing_starting_player_pos.lerp(
			target_ledge_grabbing_climb_pos,
			ledge_climb_progress * ledge_climb_progress # -- x^2 easing
		)
		#velocity = (target_pos - global_position) / delta
	
	
	if ledge_climb_progress >= 1.0 or move_input.y < -0.6:
		$CollisionShape2D.set_deferred("disabled", false)
		ledge_grab_buffer_timer.start()
		movement_state_transition_to( MovementStates.FALLING)


func portal_state_fn( _delta: float ) -> void:
	# -- maybe do some vfx here
	pass


@onready var floor_checking_rays: Array[RayCast2D] = [$FloorCheckContainer/RHS,
$FloorCheckContainer/RayCast2D, $FloorCheckContainer/LHS]

func toggle_all_collision_masks(b: bool) -> void:
	# -- on player capsule
	set_collision_mask_value(1, b)
	set_collision_mask_value(2, b)
	set_collision_mask_value(3, b)
	set_collision_mask_value(4, b)
	
	# -- on floor checking rays
	for _ray in floor_checking_rays:
		_ray.set_collision_mask_value(1, b)
		_ray.set_collision_mask_value(3, b)


func start_cloud_descent():
	toggle_all_collision_masks(false)
	movement_state_transition_to(MovementStates.CLOUD)

@onready var cloud_move_speed = 2. * kd.baseline_speed
func cloud_state_fn( _delta: float ) -> void:
	#if !$Cloud.visible:
		#$Cloud.visible = true
	velocity.y = max(move_toward(velocity.y, -move_input.y * cloud_move_speed, kd.MOV_ACCL),
					0.1 * cloud_move_speed)
	velocity.x = move_toward(velocity.x, move_input.x * cloud_move_speed, kd.MOV_ACCL)
	if my_is_on_floor():
		print(name.to_int())
		touched_bottom.emit( name.to_int() )
		$Cloud.visible = false
		toggle_all_collision_masks(true)
		movement_state_transition_to( MovementStates.IDLE )


func movement_state_transition_to(new_movement_state: MovementStates):
	if movement_state != new_movement_state:
		match movement_state:
			MovementStates.IDLE:
				match new_movement_state:
					MovementStates.JUMPING:
						current_platform = null
					MovementStates.FALLING:
						current_platform = null
			MovementStates.WALKING:
				match new_movement_state:
					MovementStates.JUMPING:
						current_platform = null
					MovementStates.FALLING:
						current_platform = null
			MovementStates.JUMPING:
				match new_movement_state:
					MovementStates.FALLING:
						hang_time_modifier = 1.0
					MovementStates.WALL_SLIDING:
						velocity = velocity.clamp(Vector2(0., 50), Vector2(0., 100))
			MovementStates.FALLING:
				hang_time_modifier = 1.0
				var play_landing_effect = false
				match new_movement_state:
					MovementStates.CLOUD:
						$Cloud.visible = true
						#print(multiplayer.get_unique_id())
					MovementStates.IDLE:
						g = kd.fall_gravity
						play_landing_effect = true
					MovementStates.WALL_SLIDING:
						velocity = velocity.clamp(Vector2(0., 50), Vector2(0., 150))
					MovementStates.JUMPING:
						if last_tocuhing_surface_state == MovementStates.WALL_SLIDING:
							Events.world_effect.emit(
									name.to_int(), 
									Effects.EffectNames.WALL_JUMP, 
									global_position - Vector2(0., $CollisionShape2D.shape.height / 2.),
									true if last_wall_normal.x < 0 else false)
				if play_landing_effect:
					Events.world_effect.emit(
						name.to_int(), 
						Effects.EffectNames.LANDING_SMOKE, 
						global_position - Vector2(0., $CollisionShape2D.shape.height / 2.),
						false)
					Events.emit_signal("play_world_sound",
										AudioDb.WorldSoundId.JUMP_LAND,
										global_position,0,randf_range(0.8, 1.20),
										{})
			MovementStates.WALL_SLIDING:
				match new_movement_state:
					MovementStates.JUMPING:
						Events.world_effect.emit(
							name.to_int(), 
							Effects.EffectNames.WALL_JUMP, 
							global_position - Vector2(0., $CollisionShape2D.shape.height / 2.),
							true if last_wall_normal.x < 0 else false)
			MovementStates.RUNNING:
				$StaminaVisual.use( false )
		# ----------------------------------
		if new_movement_state in [MovementStates.IDLE, MovementStates.WALKING, MovementStates.WALL_SLIDING]:
			last_tocuhing_surface_state = new_movement_state
		set_debug_label( new_movement_state )
		movement_state = new_movement_state


# ------------------------------------------------------- utils
func gravity_from_state():
	match movement_state:
		MovementStates.IDLE:
			return kd.jump_gravity
		MovementStates.WALKING:
			return  kd.jump_gravity
		MovementStates.RUNNING:
			return  kd.jump_gravity
		MovementStates.JUMPING:
			return kd.jump_gravity
		MovementStates.FALLING:
			return kd.fall_gravity
		MovementStates.CROUCHING:
			return kd.jump_gravity
		MovementStates.WALL_SLIDING:
			return kd.fall_gravity / 100.0
		MovementStates.LEDGE_GRABBING:
			return 0
		MovementStates.ITEM_MOVING:
			return kd.jump_gravity
		MovementStates.CLIMBING:
			return 0
		MovementStates.CLOUD:
			return 0
		MovementStates.PORTAL:
			return 0


func entered_portal():
	velocity = Vector2.ZERO
	movement_state_transition_to( MovementStates.PORTAL )


func exited_portal():
	movement_state_transition_to( MovementStates.IDLE )


func slow(b: bool):
	var slow_factor = 0.5
	if b:
		move_speed_modifier *= slow_factor
		jump_speed_modifier *= slow_factor
		gravity_modifier *= slow_factor
	else:
		move_speed_modifier /= slow_factor
		jump_speed_modifier /= slow_factor
		gravity_modifier /= slow_factor
	

# -- Utils to keep kinematic state straight with the outside world
func get_g() -> float:
	return (gravity_from_state() * gravity_modifier * hang_time_modifier)


func can_parachute() -> bool:
	return (movement_state == MovementStates.FALLING or movement_state == MovementStates.JUMPING)


func can_pick_up_item():
	return $ItemManager.can_pick_up()


func take_pickup_item(spawn_id:int, item_lookup: ItemsDb.ItemNames):
	$ItemManager.pick_up(spawn_id, item_lookup)


func drop_pickup_item(item_slot_index=null, delete_now=false):
	$ItemManager.drop_item(item_slot_index, delete_now)
	
func host_confirmed_drop():
	$ItemManager.host_confirmed_item_deletion()


func can_collect_coints() -> bool:
	return movement_state != MovementStates.CLOUD

# ------------------------------------------------------------------------------
var max_pickup_item_throw_magnitude := 1000

func apply_command( c: PlayerCommand):
	move_input = c.move_input
	if c.jump_pressed:
		jump_buffer_timer.start()

	if c.jump_released and movement_state == MovementStates.JUMPING:
		velocity.y *= 0.4
		movement_state_transition_to(MovementStates.FALLING)
	#print("aiming dir from cmd: ", c.aiming_input)
	
	# -- FIXME in local player controller
	# -- I'm accounting for this in dropped_pickup_item
	# -- this is cruft from the aiming visuals and needs to be corrected
	#func aiming_pos() -> Vector2:
	#	return (aiming_vector() + global_position)

	if c.item_dropped:
		var item_data = $ItemManager.get_current_item_data()
		if item_data[0] >= 0: # -- the item db enum
			# -- signal connected to world_pickup_items_manager:
			# -- on_player_dropped_pickup_item
			if is_multiplayer_authority():
				drop_pickup_item()
				dropped_pickup_item.emit( item_data[0], 
										  item_data[1],
										  [global_position,
										   Vector2.ZERO,
										   #max_pickup_item_throw_magnitude * 
										  #(c.aiming_input - global_position).normalized(), 
										   get_g()])


	var _run_bool = c.sprint_held and can_run
	$StaminaVisual.use( _run_bool )
	if _run_bool:
		if (movement_state == MovementStates.IDLE or
			movement_state == MovementStates.WALKING):
			movement_state_transition_to(MovementStates.RUNNING)
	else:
		if (movement_state == MovementStates.RUNNING and
			c.sprint_held):
			movement_state_transition_to(MovementStates.WALKING)
		#else:
			#movement_state_transition_to(MovementStates.IDLE)

#@rpc("any_peer", "reliable")
#func request_inventory_slot_swap(slot_index: int) -> void:
	#if not multiplayer.is_server():
		#return
	#$ItemManager.equip_inventory_slot(slot_index)
	#broadcast_inventory_slot_swap.rpc(slot_index)
#
#
#@rpc("authority", "call_remote", "reliable")
#func broadcast_inventory_slot_swap(slot_index: int) -> void:
		#$ItemManager.equip_item_locally(slot_index)
		
	# -- this is a bit fragile I think, we only have an input manager
	# -- if we're multiplayer authority
	#$ItemManager.use_item(c.item_use_pressed)
	#var aim_dir: Vector2 = Vector2.ZERO
	#var using_controller := false
	#var carrying_item := false

	# -- client side predication stuff
	#var sequence_id := 0
# ------------------------------------------------------------------------------
#
#--TODO
# -- completely replace this w/ proper visual, just here for tmp feedback
#var can_burn: bool = true
#func tmp_burn_handle() -> void:
	#var d = abs((global_position.y + 0.5 * $CollisionShape2D.shape.height)- lava_ref.lava_fn( global_position.x))
	#var hit_lava = d < 5
	#
	#if can_burn and hit_lava and lava_ref:
		#var mat = $Sprite2D.material
		#var burn_tween = create_tween()
		#mat.set_shader_parameter("dummy_burn_timer", 0.)
		#burn_tween.tween_property(mat, "shader_parameter/dummy_burn_timer", 5.0, 3.)
		#can_burn = false
#
	## -- going back accross lava threshold after getting burned
	#if !can_burn and hit_lava:
		#can_burn = true
