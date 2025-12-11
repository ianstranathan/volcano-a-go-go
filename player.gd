extends CharacterBody2D

@export_group("Kinematics")
@export var move_speed: float = 200
@export var ACCL = 20
@export var DECL = 30
@export var jump_height: float = 200;
@export var jump_distance_to_peak: float = 120
@export var fall_distance_from_peak: float = 100

@onready var time_to_peak = jump_distance_to_peak / move_speed
@onready var time_to_ground = fall_distance_from_peak / move_speed

@onready var jump_gravity = 2 * jump_height / (time_to_peak * time_to_peak);
@onready var fall_gravity = 2 * jump_height / (time_to_ground * time_to_ground);
@onready var jump_speed = -2 * jump_height / time_to_peak;


@export_group("platformer stuff")
## Time to allow jump after leaving ground
@export var COYOTE_TIME_DURATION: float = 0.15
# Time to hold jump input for later jump
@export var JUMP_BUFFER_DURATION: float = 0.15

@onready var coyote_timer: Timer = $CoyoteTimeTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

@onready var new_y_vel: float = velocity.y

var is_on_ground = true


func _ready() -> void:
	coyote_timer.wait_time = COYOTE_TIME_DURATION
	jump_buffer_timer.wait_time = JUMP_BUFFER_DURATION

	coyote_timer.timeout.connect( func():
		is_on_ground = false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_buffer_timer.start()

func handle_jump():
	# -- if our "truth" about being on the ground (e.g. slightly off ledge)
	if is_on_ground and !jump_buffer_timer.is_stopped():
		is_on_ground = false
		velocity.y += jump_speed
		

func _physics_process(delta: float) -> void:
	move();
	handle_jump()
	
	if !my_is_on_floor(): # -- coyote time check
		coyote_timer.start()
	
	var g = fall_gravity if velocity.y >= 0  else jump_gravity
	global_position += (velocity * delta) + Vector2(0., (0.5 * delta * delta * g))
	velocity.y += g * delta

	var coll = move_and_collide(Vector2.ZERO)
	if coll:
		var normal = coll.get_normal()
		if normal.y < 0:
			is_on_ground = true
			velocity.y = 0
	

func move():
	var move_input := Input.get_axis("move_left", "move_right")
	var there_is_input: bool = !is_zero_approx(move_input)
	var _accl = ACCL if there_is_input else DECL
	var target_move_speed = move_input * move_speed if there_is_input else 0.0;
	velocity.x = move_toward(velocity.x, target_move_speed, _accl)
 

func my_is_on_floor() -> bool:
	# -- is any ray colliding with something?
	return $FloorCheckContainer.get_children().reduce(func(accum, child):
		return (accum or child.is_colliding()), false)
