extends Node2D

## how close to the lava in pixels to count as in lava
@export var lava_dist_threshold: float = 30

var lava_ref: TheLava = null:
	set(value):
		lava_ref = value
		#print("lava got set in lava component:", value)
var is_in_lava: bool = false

@export var moveable_component_ref: Node2D
@onready var p: AnimatableBody2D = get_parent()
#@onready var lava_level_offset = p.get_node("CollisionShape2D").shape.size.y / 2.

func execute_tick(delta: float) -> void:
	lava_dist_threshold = lerp(30, 200, moveable_component_ref.velocity.y / moveable_component_ref.TERMINAL_VEL_Y)
	
	if lava_ref:
		if is_in_lava:
			var y = lava_ref.lava_fn( global_position.x)
			var a = lava_ref.angle_to_lava_fn( global_position.x)
			
			p.global_transform = Transform2D(lerp(global_rotation, a, delta),
										   Vector2(global_position.x, y))
		else:
			if hit_lava():
				is_in_lava = true
				moveable_component_ref.stop_falling()

func hit_lava() -> bool:
	var _pos = p.global_position
	#print(_pos.y - lava_ref.lava_fn( _pos.x))#)
	var ret = abs(_pos.y - lava_ref.lava_fn( _pos.x)) < lava_dist_threshold
	#print(p.name, ": ",  ret, ", with threshold: ", lava_dist_threshold)
	return ret
