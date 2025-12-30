extends Item

@export var swing_power: float = 100 # -- coefficient for swinging manually
@export var reel_in_speed: float = 50
@export var grapple_change_rate := 200.0
@export var swing_damping := 1.0
# ----------------------------
@export var grapple_max_distance: float = 800
@export var grapple_min_distance: float = 50

@onready var rest_length = grapple_min_distance
#@export var stiffness = 15.0
#@export var damping = 5.0

@onready var ray := $RayCast2D
@onready var rope := $Line2D


var launched = false
var target: Vector2


func _ready() -> void:
	$RayCast2D.target_position = Vector2(grapple_max_distance, 0.0)


func _physics_process(delta: float) -> void:
	ray.look_at(input_manager.aiming_pos())
	if launched:
		handle_grapple(delta)
	if Input.is_action_just_pressed("use_item"):
		use()
	if Input.is_action_just_released("use_item"):
		finish_using()
	
	# -- inverting these to match intuion
	var move_input := Input.get_axis("move_up", "move_down")
	rest_length += delta * move_input * grapple_change_rate
	rest_length = clamp(rest_length, grapple_min_distance, grapple_max_distance)


func use():
	super()
	launch()

func finish_using():
	super()
	retract()

func launch():
	#print("launching")
	if ray.is_colliding():
		launched = true
		target = ray.get_collision_point()
		#rope.set_point_position(1, to_local(target))
		rope.show()


func retract():
	launched = false
	rope.hide()


#func handle_grapple(delta):
	#var target_dir = player_ref.global_position.direction_to(target)
	#var target_dist = player_ref.global_position.distance_to(target)
	#var displacement = target_dist - rest_length
	#var force = Vector2.ZERO
	#if displacement > 0:
		#var spring_force_magnitude = stiffness * displacement
		#var spring_force = target_dir * spring_force_magnitude
		#
		#var vel_dot = player_ref.velocity.dot(target_dir)
		#var _damping = -damping * vel_dot * target_dir
		#force = spring_force + _damping
	#player_ref.velocity += force * delta
	#update_rope()
func handle_grapple(delta):
	var to_anchor = target - player_ref.global_position
	var current_dist = to_anchor.length()
	var target_dir = to_anchor.normalized()
	
	# Reel in logic
	rest_length = max(rest_length - reel_in_speed * delta, 20.0)

	if current_dist > rest_length:
		# 1. THE VELOCITY CONSTRAINT
		# Check if we are moving away from the anchor
		var outward_vel = player_ref.velocity.dot(target_dir)
		
		if outward_vel < 0:
			# This is the magic step:
			# We remove ONLY the velocity component pointing away from the anchor.
			# This redirects the player's momentum into a tangent (the swing).
			player_ref.velocity -= target_dir * outward_vel
		
		# 2. THE SMOOTH PULL (Pseudo-Position)
		# Instead of snapping position, we calculate the 'correction velocity'
		# needed to close the distance gap over a very short time.
		var overshoot = current_dist - rest_length
		
		# We use a high 'Responsiveness' value (e.g., 1/0.1 meaning it closes in 0.1s)
		# This moves the player toward the constraint without a 'spring' bounce.
		var responsiveness = 0.5
		player_ref.velocity += target_dir * (overshoot * responsiveness)
		
		# 3. CENTRIPETAL STABILIZATION
		# When swinging, gravity pulls you down, but the rope pulls you in.
		# This keeps the player from 'drifting' outward due to integration errors.
		#if player_ref.velocity.length() > 0.1:
			#var tangent = player_ref.velocity.normalized()
			## Ensure the velocity stays perpendicular to the rope
			#player_ref.velocity = player_ref.velocity.project(tangent)
	#apply_swing_mechanics(target_dir, delta)
	
	player_ref.velocity *= (1.0 - (swing_damping * delta)) # -- Damping / Friction
	update_rope()


#func apply_swing_mechanics(target_dir: Vector2, delta: float) -> void:
	## 2. Add "Swing" Momentum (The Titanfall Feel)
	## Give the player extra acceleration based on their input, perpendicular to the rope
	#var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	#if input_dir.length() > 0:
		## This allows the player to "swing" faster by holding move keys
		#var swing_force = input_dir * swing_power 
		#player_ref.velocity += swing_force * delta
#
	## 3. Constant Pull (Optional)
	## Titanfall grapples also slowly reel you in
	#player_ref.velocity += target_dir * reel_in_speed * delta

func update_rope():
	rope.set_point_position(1, to_local(target))
