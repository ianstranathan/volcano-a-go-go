extends Camera2D


var target: Player
var horizontal_look_ahead_distance: float
var vertical_look_ahead_distance: float

@export_group("Smoothing")
@export var lead_speed: float = 5.0    
@export var follow_speed: float = 10.0
var target_offset: Vector2 = Vector2.ZERO

func _ready():
	viewport_size_change_callback()
	get_viewport().size_changed.connect( viewport_size_change_callback )


func _physics_process(delta: float) -> void:
	if not target:
		return
	var desired_offset_x = get_persistent_direction() * horizontal_look_ahead_distance
	target_offset.x = lerp(target_offset.x, desired_offset_x, lead_speed * delta)
	var desired_position = target.global_position + target_offset
	global_position = global_position.lerp(desired_position, follow_speed * delta)


var last_direction: float = 1.0
func get_persistent_direction() -> float:
	var current_velocity = target.velocity.x
	if not is_zero_approx(current_velocity):
		last_direction = sign(current_velocity)
	return last_direction


func viewport_size_change_callback():
	var vp = get_viewport()
	horizontal_look_ahead_distance = vp.size.x / 12.0
	#vertical_look_ahead_distance = vp.size.y / 14.0


func target_initialize( player: Player) -> void:
	target = player
	global_position = player.global_position
	#target.local_controller_added.connect( func(lc: LocalPlayerController):
		#local_controller_ref = lc)
	#target.started_falling.connect( func():
		#print("started falling")
		#)
