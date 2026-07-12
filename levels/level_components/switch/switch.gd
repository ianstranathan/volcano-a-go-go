@tool
extends Node2D

signal switch_finished

var can_move

var _coll_extents: Vector2 = Vector2(50., 50.)
@export var speed: float
enum SwitchType{
	IMMEDIATE,
	PRESSURE
}
@export var switch_type: SwitchType = SwitchType.PRESSURE

@export var base_platform: BasePlatform
@export var coll_extents: Vector2:
	set(value):
		_coll_extents = value
		if base_platform:
			base_platform.coll_extents = value  # forward to child
			#collision_dimensions_changed.emit(value)
	get:
		if base_platform:
			return base_platform.coll_extents
		return _coll_extents

func _ready() -> void:
	if base_platform:
		base_platform.coll_extents = _coll_extents
		
	if not Engine.is_editor_hint():
		#print(speed)
		$BasePlatform/MovingPlatformComponent.movement_finished.connect( func():
			print("movement_finished emitted")
			switch_finished.emit())
		base_platform.get_node("MovingPlatformComponent").speed = speed
		# -- starting pos
		await get_tree().process_frame
		$PathFollowPlatformComponent.curve.clear_points()
		$PathFollowPlatformComponent.curve.add_point(Vector2.ZERO)
		# -- ending pos (half way down)
		$PathFollowPlatformComponent.curve.add_point( 
			Vector2(0., $BasePlatform.coll_extents.y / 2.0))
		$BasePlatform/MovingPlatformComponent.calc_path_length()
		#base_platform.get_node("MovingPlatformComponent").recalculate_path_length()
		var a = $BasePlatform.get_node("Area2D")
		a.body_entered.connect( on_body_entered )
		a.body_exited.connect( on_body_exited_mkr(a) )


func on_body_entered( body ):
	if body is Player:
		var v = (body.global_position - global_position).normalized()
		if v.dot( Vector2.UP ) > 0.9:
			if !can_move:
				can_move = true
			else:
				$BasePlatform/MovingPlatformComponent.reverse()


func on_body_exited_mkr( a: Area2D) -> Callable:
	return func(body):
		if body is Player and can_move:
			#var v = (body.global_position - global_position).normalized()
			#print(v)
			#print(v.dot( Vector2.UP ))
			#print(a.get_overlapping_bodies().size())
			if a.get_overlapping_bodies().size() == 0:
				#print("yomu")
				$BasePlatform/MovingPlatformComponent.reverse()


func execute_tick(delta: float):
	if can_move:
		$BasePlatform.execute_tick(delta)
