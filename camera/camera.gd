extends Camera2D

# -- TODO + FIXME
# -- This is quick and deerty
"""
Goals for camera movement:
	1) frames jumping 
	   (shouldn't change elevation until the player goes beyond some threshold & lands OR goes off screen)
	   -> why? this allows more precise control over jumping (it's a platformer afterall)
	2) look ahead (orient in direction of player movement and be slightly ahead of it)
	 
	Lerping when changing directions should be faster than lerping in same dir
"""

var lerp_x_t:= 0.0

@export var target: CharacterBody2D
@export var target_height_offset: float
@onready var target_x_dir: float
# -- maximum offset in pixels
var MAX_OFFSET = 200.0
# -- this is just for faster comparisons
@onready var MAX_OFFSET_sqrd = MAX_OFFSET * MAX_OFFSET
# -- this is viewport dependent, might be good to export?
var platform_vertical_threshold
var falling_vertical_threshold

var lerping_to_turned_dir := false


func _ready():
	assert(target)
	set_vertical_movement_thresholds()
	get_tree().get_root().size_changed.connect(set_vertical_movement_thresholds)
	global_position = Vector2(target.global_position.x + (MAX_OFFSET), target.global_position.y)


# -- needs to be a separate function for callbacks
func set_vertical_movement_thresholds() -> void:
	var vp_size_y =  get_viewport().size.y
	platform_vertical_threshold = vp_size_y / 3.0
	falling_vertical_threshold = vp_size_y / 2.5


func _physics_process(delta):
	if !target:
		return

	# -- set the dir if it's null, we always want to be looking ahead a little
	if !target_x_dir:
		target_x_dir = sign(target.velocity.x)
	# -- check to see if the camera is pointing in the same direction as the player
	else:
		if target.velocity.x != 0.0:
			var s = sign(target.velocity.x)
			if target_x_dir != s:
				lerping_to_turned_dir = true
				lerp_x_t = 0.0
			target_x_dir = s

		# -- 
		var target_x = target.global_position.x + (MAX_OFFSET * target_x_dir)
		var dist_to_target = abs(target_x - global_position.x)
	
		if !dist_to_target < 2.0:
			if !lerping_to_turned_dir:
				global_position.x = target_x
			else:
				lerp_x_t += 0.25 * delta
				var t = 1.0 - cos(lerp_x_t * PI / 2.0);
				global_position.x = (1. - t) * global_position.x + t * target_x 
				#global_position.x = lerp(global_position.x, target_x, delta * delta)
		else:
			if lerping_to_turned_dir:
				lerp_x_t = 0.0
				lerping_to_turned_dir = false

	# -- update y position if the player crosses some threshold & lands on the platform
	# -- this allows the player to make a jump without the camera changing
	if abs(target.global_position.y - global_position.y) >= platform_vertical_threshold and target.is_on_floor():
		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position:y", target.global_position.y, 0.3)
		tween.set_parallel(true)
	# -- otherwise, change if the player nears the edge of the screen in y dir (falling)
	elif abs(target.global_position.y - global_position.y) >= falling_vertical_threshold:
		#global_position.y = target.global_position.y
		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position:y", target.global_position.y, 0.2)
		tween.set_parallel(true)
