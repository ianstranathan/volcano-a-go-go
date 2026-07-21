@tool
extends Node2D

enum OpenType{
	INCREMENTALLY,
	AT_END
}
enum MoveDirection{
	UP,
	DOWN
}
var _coll_extents: Vector2 = Vector2(50, 50) # Give it a default matching the child

@export var speed: float = 50.0

@export var move_dir: MoveDirection
@export var switch: Node2D
@export var base_platform: BasePlatform

var can_move := false

@export var coll_extents: Vector2:
	set(value):
		_coll_extents = value
		# Instead of is_node_ready(), just check if the reference exists
		if base_platform:
			base_platform.coll_extents = value
	get:
		if base_platform:
			return base_platform.coll_extents
		return _coll_extents

@export var path_component: PathFollowPlatformComponent:
	set(value):
		path_component = value
		if base_platform and base_platform.get_node("MovingPlatformComponent"):
			base_platform.get_node("MovingPlatformComponent")._path_follower_component = value

@onready var moving_platform_component: MovingPlatformComponent
func _ready():
	if base_platform:
		base_platform.coll_extents = _coll_extents
	#can_move = true
	if not Engine.is_editor_hint():
		assert(move_dir != null)
		assert(switch)
		assert(path_component)
		path_component.curve.clear_points()
		path_component.curve.add_point(Vector2.ZERO)
		path_component.curve.add_point( 
			Vector2(0., 
			 (-1.0 if move_dir == 1 else 1.0) * base_platform.coll_extents.y))
		
		assert(switch.has_signal("switch_finished"))
		assert(base_platform.get_node("MovingPlatformComponent"))
		# -- first point of path should be where the door is
		#path_component.curve.set_point_position(0, global_position)
		
		# -- NOTE!!!!!!!!!!!!!!!!!!!!!!!
		path_component.global_position = global_position

		#assert($BasePlatform/MovingPlatformComponent)
		moving_platform_component = base_platform.get_node("MovingPlatformComponent")
		moving_platform_component.moving = false
		moving_platform_component._path_follower_component = path_component
		moving_platform_component.calc_path_length()
		#base_platform.get_node("MovingPlatformComponent").set_path(path_component)
		switch.switch_finished.connect( on_switch_finished )
		
	
		
		base_platform.get_node("Area2D").monitoring = false
		base_platform.get_node("Area2D").monitorable = false


func on_switch_finished():
	moving_platform_component.set_target_time(1.0)


func execute_tick(delta: float):
	base_platform.execute_tick(delta)
