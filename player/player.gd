extends CharacterBody2D

class_name Player
# -- TODO
# -- account for terminal velocity
# -- (should only be able to fall so fast)
# -- [X] Side somersault
# -- [X] Wall Slide
# -- Wall Bonk
# -- Head Bonk

@export_group("Kinematics")
@export var move_speed: float = 200
@export var ACCL = 20
@export var DECL = 30
@export var jump_height: float = 200;
@export var jump_distance_to_peak: float = 120
@export var fall_distance_from_peak: float = 100
@export var somersault_factor = 1.25 ## as a ratio of the jump velocity

@onready var time_to_peak = jump_distance_to_peak / move_speed
@onready var time_to_ground = fall_distance_from_peak / move_speed

@onready var jump_gravity = 2 * jump_height / (time_to_peak * time_to_peak);
@onready var fall_gravity = 2 * jump_height / (time_to_ground * time_to_ground);
@onready var wall_slide_gravity = fall_gravity / 1000.0
@onready var jump_speed = -2 * jump_height / time_to_peak;

var current_platform = null # -- for calculating relative velocities
var last_move_input: float  # -- side somersault variable
var move_input: float
@export_group("platformer stuff")
## Time to allow jump after leaving ground
@export var COYOTE_TIME_DURATION: float = 0.15
## Time to hold jump input for later jump
@export var JUMP_BUFFER_DURATION: float = 0.15
## number of pixels to snap character to (for vertically moving platforms)
@export var platform_snap_distance = 20
@onready var coyote_timer: Timer = $CoyoteTimeTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer


var is_on_ground := true # -- our "truth" about being on the ground (e.g. slightly off ledge)
@onready var g: float = jump_gravity

@export_category("Lava")
# -- TODO NOTE
@export var lava_ref: Node2D

enum MovementStates
{
	IDLE,
	WALKING,
	JUMPING,
	FALLING,
	CROUCHING,
	WALL_SLIDING,
	LEDGE_GRABBING,
	ITEM_MOVING
}
@export var movement_state: MovementStates = MovementStates.IDLE

#var item_is_overriding_velocity: bool = false

func _ready() -> void:
	$ItemManager.item_started.connect( func():
		movement_state_transition_to( MovementStates.ITEM_MOVING))
	$ItemManager.item_finished.connect( func():
		movement_state_transition_to( MovementStates.FALLING))
		
	assert(lava_ref)
	coyote_timer.wait_time = COYOTE_TIME_DURATION
	jump_buffer_timer.wait_time = JUMP_BUFFER_DURATION

	coyote_timer.timeout.connect( func():
		movement_state_transition_to(MovementStates.FALLING)
		is_on_ground = false)

	$WallJumpTimer.timeout.connect( func():
		# -- turn on all the wall raycasts after a certain amount time after wall jump
		$WallCheckContainer.get_children().map( 
			func(child): child.enabled = true))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_buffer_timer.start()
	# -- this is for short jumps
	if (event.is_action_released("jump") and 
		movement_state == MovementStates.JUMPING):
		velocity.y = 0.0
		movement_state_transition_to(MovementStates.FALLING)

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
			if !$SideSomersaultTimer.is_stopped():
				do_jump(JumpTypes.SOMERSAULT_FLIP)
			else:
				do_jump(JumpTypes.REGULAR)
		elif is_wall_sliding():
			do_jump(JumpTypes.WALL)
		elif is_ledge_grabbing():
			do_jump(JumpTypes.REGULAR)


func do_jump(jump_type):
	# -- logic of what to do for a specific jump
	jump_buffer_timer.stop()
	match jump_type:
		JumpTypes.REGULAR:
			velocity.y = jump_speed
		JumpTypes.SOMERSAULT_FLIP:
			velocity.y = jump_speed * somersault_factor
			var tween = create_tween()
			tween.tween_property(self, "global_rotation", global_rotation + sign(last_move_input) * TAU, time_to_peak)
		JumpTypes.WALL:
			var _wall_normal = wall_normal()
			if _wall_normal:
				velocity = jump_speed * (-_wall_normal  + Vector2.DOWN).normalized()
	movement_state_transition_to(MovementStates.JUMPING)


func _physics_process(delta: float) -> void:
	
	move_input = Input.get_axis("move_left", "move_right")
	if !last_move_input: # -- initializing last_move_input
		last_move_input = move_input
	
	# -- call the movement state function matching the movement_state variable
	call(MovementStates.keys()[movement_state].to_lower() + "_state_fn")
	tmp_burn_handle() # TODO # -- temporary burn visual feedback
	
	if current_platform: # -- account for relative velocities
		move_and_collide(current_platform.get_velocity() * delta)
	
	# -- velocity verlet update
	global_position += (velocity * delta) + Vector2(0., (0.5 * delta * delta * g))
	velocity.y += g * delta
	var collision = move_and_collide(Vector2.ZERO)
	if collision:
		# -- projection of ground normal is mostly vertical
		is_on_ground = collision.get_normal().dot(Vector2.UP) > 0.7
		if is_on_ground:
			current_platform_check( collision )
			velocity.y = 0

	last_move_input = move_input


func current_platform_check(coll: KinematicCollision2D):
	var collider = coll.get_collider()
	if collider is MoveablePlatform:
		current_platform = collider


func there_is_move_input():
	return !is_zero_approx(move_input)


func my_is_on_floor() -> bool:
	# -- is any downward pointing ray colliding with something?
	# -- the built in "is_on_floor()" only works with move_and_slide
	return $FloorCheckContainer.get_children().reduce(func(accum, child):
		return (accum or child.is_colliding()), false)


func is_falling():
	return velocity.y >= 0 and not my_is_on_floor()


func is_wall_sliding() -> bool:
	# -- is the wall ray pointed in the opposite direction as the wall normal
	var _wall_normal = wall_normal()
	if _wall_normal:
		return last_move_input * _wall_normal.x < 0
	return false


func wall_normal():
	# -- return the first raycast collision normal
	# -- TODO
	# -- this will fail if there collisions on both side of player
	for ray in $WallCheckContainer.get_children():
		if ray.is_colliding():
			return ray.get_collision_normal()


@onready var rhs_ledge_grab_pair: Array[RayCast2D] = [$LedgeRayContainer/RHS, $WallCheckContainer/RHS1]
@onready var lhs_ledge_grab_pair: Array[RayCast2D] = [$LedgeRayContainer/LHS, $WallCheckContainer/LHS1]
@onready var ledge_grab_arrs = [rhs_ledge_grab_pair, lhs_ledge_grab_pair]
func is_ledge_grabbing() -> bool:
	var arr = lhs_ledge_grab_pair if last_move_input < 0 else rhs_ledge_grab_pair
	var ledge_ray = arr[0]
	var wall_ray = arr[1]
	return wall_ray.is_colliding() and !ledge_ray.is_colliding()


func ledge_grabbing_climb_position():
	var arr = lhs_ledge_grab_pair if last_move_input < 0 else rhs_ledge_grab_pair
	var ledge_ray = arr[0]
	var wall_ray = arr[1]
	# -- relative position between rays
	var rel_pos = ((ledge_ray.global_position + ledge_ray.target_position) - (wall_ray.global_position + wall_ray.target_position))
	var height_between_rays = ledge_ray.global_position.y -  wall_ray.global_position.y
	return (global_position - Vector2(0., $CollisionShape2D.shape.height - height_between_rays) 
			+ rel_pos)

func set_debug_label(new_movement_state: MovementStates) -> void:
	$Label.text = MovementStates.keys()[new_movement_state]


#------------------------------------------------- movement state fns
func move(target_speed: float, 
		  x_rate_change: float, 
		  should_check_for_falling: bool = false) -> void:
	velocity.x = move_toward(velocity.x, target_speed, x_rate_change)
	if should_check_for_falling and is_falling() and coyote_timer.is_stopped():
		coyote_timer.start()  # -- transitions to FALLING on timeout


func idle_state_fn() -> void:
	check_for_jump()
	move(0.0, DECL, true)
	if there_is_move_input():
		movement_state_transition_to( MovementStates.WALKING)


func walking_state_fn() -> void:
	check_for_jump()
	## -- side somersault check:
	## -- two -tive nums multiplied together is a positive
	## -- two +tive nums multiplied together is a positive
	## -- two differnt signed nums multiplied together is a negative
	if there_is_move_input():
		move(move_input * move_speed, ACCL, true)
		var switched_dir = true if last_move_input * move_input < 0 else false
		if switched_dir:
			$SideSomersaultTimer.start()
	else:
		movement_state_transition_to(MovementStates.IDLE)


func jumping_state_fn() -> void:
	if there_is_move_input():
		move(move_input * move_speed, ACCL)
	if is_falling():
		movement_state_transition_to(MovementStates.FALLING)


var ledge_grab_climb_pos: Vector2
func falling_state_fn() -> void:
	check_for_jump() # -- to jump from item moving
	if there_is_move_input():
		# -- maybe we wanna go through the air slightly slower?
		move(move_input * move_speed, ACCL)
	# ++++++++++++++++
	if is_ledge_grabbing() and $LedgeGrabBufferTimer.is_stopped():
		# -- we stop gravity and falling velocity, save the climbing pos
		velocity = Vector2.ZERO
		g = 0
		ledge_grab_climb_pos = ledge_grabbing_climb_position()
		movement_state_transition_to(MovementStates.LEDGE_GRABBING)
	elif is_wall_sliding():
		movement_state_transition_to(MovementStates.WALL_SLIDING)
	elif my_is_on_floor():
		movement_state_transition_to(MovementStates.IDLE)


func wall_sliding_state_fn() -> void:
	check_for_jump()
	if my_is_on_floor():
		movement_state_transition_to(MovementStates.IDLE)
	elif is_ledge_grabbing():
		velocity = Vector2.ZERO
		g = 0
		ledge_grab_climb_pos = ledge_grabbing_climb_position()
		movement_state_transition_to(MovementStates.LEDGE_GRABBING)
	if !is_wall_sliding():
		movement_state_transition_to(MovementStates.FALLING)


func item_moving_state_fn() -> void:
	pass


var ledge_climb_speed = 100.0
func ledge_grabbing_state_fn() -> void:
	check_for_jump()
	if Input.is_action_just_pressed("move_up"):
		global_position.move_toward(ledge_grab_climb_pos, 0.06)
		#velocity = (ledge_grab_climb_pos - global_position).normalized() * ledge_climb_speed
	elif Input.is_action_just_pressed("move_down"):
		$LedgeGrabBufferTimer.start()
		movement_state_transition_to( MovementStates.FALLING)
	if my_is_on_floor():
		movement_state_transition_to( MovementStates.IDLE)
	

# -- wrap this up into a more functional, modular thing to inject states into matches
func movement_state_transition_to(new_movement_state: MovementStates):
	if movement_state != new_movement_state:
		match movement_state:
			MovementStates.IDLE:
				# -- exit code here
				match new_movement_state:
					# -- enter code here
					MovementStates.WALKING:
						pass
					MovementStates.JUMPING:
						g = jump_gravity
						current_platform = null
					MovementStates.FALLING:
						g = fall_gravity
						current_platform = null
					#MovementStates.ITEM_MOVING:
						#pass
			MovementStates.WALKING:
				match new_movement_state:
					MovementStates.IDLE:
						pass
					MovementStates.JUMPING:
						g = jump_gravity
						current_platform = null
					MovementStates.FALLING:
						g = fall_gravity
						current_platform = null
			MovementStates.JUMPING:
				match new_movement_state:
					MovementStates.FALLING:
						g = fall_gravity
					MovementStates.WALL_SLIDING:
						velocity = velocity.clamp(Vector2(0., 50), Vector2(0., 100))
						g = fall_gravity / 100.0
						#g = _wall_slide_gravity()
					MovementStates.LEDGE_GRABBING:
						pass
			MovementStates.FALLING:
				match new_movement_state:
					MovementStates.IDLE:
						g = fall_gravity
					MovementStates.WALL_SLIDING:
						# -- design choice
						# -- the wall slide should be predictable, but not boring
						velocity = velocity.clamp(Vector2(0., 50), Vector2(0., 100))
						g = fall_gravity / 100.0
						#_wall_slide_gravity()
					MovementStates.LEDGE_GRABBING:
						pass
			MovementStates.CROUCHING:
				pass
			MovementStates.WALL_SLIDING:
				match new_movement_state:
					MovementStates.IDLE:
						pass
					MovementStates.JUMPING:
						g = jump_gravity
					MovementStates.FALLING:
						g = fall_gravity
			MovementStates.LEDGE_GRABBING:
				match new_movement_state:
					MovementStates.IDLE:
						pass
					MovementStates.FALLING:
						g = fall_gravity
					MovementStates.JUMPING:
						g = jump_gravity
			MovementStates.ITEM_MOVING:
				match new_movement_state:
					MovementStates.FALLING:
						g = jump_gravity
						is_on_ground = true
						coyote_timer.start()

		# ----------------------------------
		set_debug_label( new_movement_state )
		movement_state = new_movement_state


#--TODO
# -- completely replace this w/ proper visual, just here for 
# -- tmp feedback
var can_burn: bool = true
func tmp_burn_handle() -> void:
	var d = abs((global_position.y + 0.5 * $CollisionShape2D.shape.height)- lava_ref.lava_fn( global_position.x))
	var hit_lava = d < 5
	
	if can_burn and hit_lava and lava_ref:
		var mat = $Sprite2D.material
		var burn_tween = create_tween()
		mat.set_shader_parameter("dummy_burn_timer", 0.)
		burn_tween.tween_property(mat, "shader_parameter/dummy_burn_timer", 5.0, 3.)
		can_burn = false

	# -- going back accross lava threshold after getting burned
	if !can_burn and hit_lava:
		can_burn = true

# ----------------------------------------------------------- SAVE BUFFER
#const MOVEMENT_STATE_PRIORIOTY_ARR = [ 
	#MovementStates.IDLE,
	#MovementStates.WALKING,
	#MovementStates.JUMPING,
	#MovementStates.FALLING,
	#MovementStates.CROUCHING,
	#MovementStates.WALL_SLIDING,
	#MovementStates.LEDGE_HANGING,
	#MovementStates.ITEM_MOVING
#]

# -------------------------------------

# -- the wall slide gravity is too low when velocity is near 0
# -- but it feels about right for faster downward velocitys
#func _wall_slide_gravity() -> float:
	### -- t: normalization var based on velocity value
	### -- b: the maximum magnitude of the downward velocity
	### --    (I just printed out some jumps from the physics loop at picked the highest ~1800
	### -- a: always zero
	#var b = 1800.0
	## -- normalizing on range: t = b - x / b - a
	## -- simplifies to t = b - x / b
	## -- need to guarentee velocity is not above this
	#var v_y = clamp(abs(velocity.y), 0., b)
	#var t = (b - v_y) / b
	#
	## -- linear interpolation of the wall gravity value
	## -- TODO should play around with different interpolation curves base
	## -- on game feel at some later point
	#var A = 0.5 * wall_slide_gravity
	#var wall_slide_gravvity_at_zero_vel = 20 * wall_slide_gravity
	#var B = wall_slide_gravvity_at_zero_vel
	#var _t = t * t
	#var ret = (1. - _t) * A + _t * B
	##print("ret: ", ret, "at t: ", t)
	#return ret

#@onready var down_test_vector = Vector2(0, platform_snap_distance)
# ----------------------------------------------------------- Kludge to check falling platforms
		#if was_idle and movement_state == MovementStates.FALLING:
			#if test_move(global_transform, down_test_vector):
				#var snap_collision = move_and_collide(down_test_vector)
				#if snap_collision:
					#current_platform_check( snap_collision )
					#is_on_ground = true
					#velocity.y = 0
	
