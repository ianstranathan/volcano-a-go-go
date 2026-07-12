extends Node2D

class_name MovingPlatformComponent

signal movement_finished
enum MoveType{
	OSCILLATE,
	LOOP,
	MODULO,
	ONE_SHOT
}

@export var speed: float = 100.0
@export var transition_type: Tween.TransitionType = Tween.TRANS_LINEAR
@export var easing_type: Tween.EaseType = Tween.EASE_IN
@export var movement_type:MoveType = MoveType.LOOP
@export var time_direction: float = 1.0

@onready var target_to_move: AnimatableBody2D = get_parent()
@export var _root: Node2D

var network_id = -1
var _time = 0.0
var last_pos: Vector2
var displacement: Vector2 = Vector2.ZERO
var path_length: float# = _path_follower_component.get_curve().get_baked_length()

#@export var _root: Node2D
@export var _path_follower_component: PathFollowPlatformComponent:
	set(value):
		_path_follower_component = value
		path_length = _path_follower_component.get_curve().get_baked_length()

func _ready() -> void:
	assert(target_to_move)
	if _path_follower_component:
		path_length = _path_follower_component.get_curve().get_baked_length()

	last_pos = target_to_move.global_position
	# -- you slap this guy on an animated body, hook it up
	# -- then it will automatically be able to be found by player script
	target_to_move.add_to_group("moving_platforms")

var stop := false
func execute_tick(delta: float):
	
	if not target_to_move or not _path_follower_component:
		return

	if movement_type == MoveType.ONE_SHOT:
		
		if time_direction >= 0.0 and _time >= 1.0:
			displacement = Vector2.ZERO
			return
		elif time_direction < 0.0 and _time <= 0.0:
			displacement = Vector2.ZERO
			return

	if path_length:
		_time += delta * time_direction * (speed / path_length)
		#print( _time )
	#else:
		#print("len: ", _path_follower_component.curve.get_baked_length())
		#print("pts: ", _path_follower_component.curve.get_baked_points())
	# -- one shot here
	#elif not stop:
		##print(directed_delta * delta * speed)
		##print(delta * speed)
		#_time += directed_delta * speed
	# -- handle timeline wrapping based on movement type before tweening
	var tween_time = _time
	
	match movement_type:
		MoveType.OSCILLATE:
			tween_time = pingpong(_time, 1.0)
		MoveType.LOOP:
			_time = wrapf(_time, 0.0, 1.0)
			_path_follower_component.set_loop( true )
			tween_time = _time
		MoveType.MODULO:
			_path_follower_component.set_loop( false )
			_time = wrapf(_time, 0.0, 1.0)
			tween_time = _time
		MoveType.ONE_SHOT:
			_time = clamp(_time, 0.0, 1.0)
			if is_equal_approx(_time, 1.0) or is_equal_approx(_time, 0.0):
				if not stop:
					stop = true
					movement_finished.emit()
			tween_time = _time
			
	# -- if looping, force linear so it doesn't warp or change speed at the wrap point
	var current_trans = transition_type
	var current_ease = easing_type

	if movement_type == MoveType.LOOP:
		current_trans = Tween.TRANS_LINEAR
		current_ease = Tween.EASE_IN_OUT
	
	var ratio = Tween.interpolate_value(0.0, 1.0, tween_time, 1.0, current_trans, current_ease)
	
	_path_follower_component.set_progress_ratio( ratio )
	#print(target_to_move.global_position)
	target_to_move.global_position = _path_follower_component.get_path_global_position()

	displacement = target_to_move.global_position - last_pos
	last_pos = target_to_move.global_position


func set_path( p: PathFollowPlatformComponent) -> void:
	_path_follower_component = p


func reverse() -> void:
	time_direction *= -1.0
	stop = false


func calc_path_length():
	assert(_path_follower_component)
	path_length = _path_follower_component.get_curve().get_baked_length()
	#print("in here with: ", path_length)
