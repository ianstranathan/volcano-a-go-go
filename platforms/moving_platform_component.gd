extends Node2D

class_name MovingPlatformComponent

var network_id = -1

@export var target_to_move: AnimatableBody2D
@export var _root: Node2D

var _path_follower: PathFollow2D:
	set( v ):
		_path_follower = v
		assert( _path_follower.get_parent() )
		path_length = _path_follower.get_parent().get_curve().get_baked_length()

var _time = 0.0
var last_pos: Vector2
var displacement: Vector2 = Vector2.ZERO

var path_length: float
@onready var movement_type = _root.movement_type
@onready var speed = _root.speed
@onready var movement_types = _root.MoveType

var transition_type: Tween.TransitionType:
	get: return _root.transition_type

var easing_type: Tween.EaseType:
	get: return _root.easing_type
	
func _ready() -> void:
	assert(target_to_move)
	last_pos = target_to_move.global_position
	# -- you slap this guy on an animated body, hook it up
	# -- then it will automatically be able to be found by player script
	target_to_move.add_to_group("moving_platforms")


func execute_tick(delta: float):
	if not target_to_move or not _path_follower or not _root:
		return
	
	if movement_type == movement_types.ONE_SHOT and _time >= 1.0:
		displacement = Vector2.ZERO
		return
	# -- icnr normalized time
	_time += delta * (speed / path_length)
	
	# -- handle timeline wrapping based on movement type before tweening
	var tween_time = _time
	
	match movement_type:
		movement_types.OSCILLATE:
			tween_time = pingpong(_time, 1.0)
		movement_types.LOOP:
			_time = wrapf(_time, 0.0, 1.0)
			_path_follower.loop = true
			tween_time = _time
		movement_types.MODULO:
			_path_follower.loop = false
			_time = wrapf(_time, 0.0, 1.0)
			tween_time = _time
			
		movement_types.ONE_SHOT:
			_time = clamp(_time, 0.0, 1.0)
			tween_time = _time
			
	# -- if looping, force linear so it doesn't warp or change speed at the wrap point
	var current_trans = transition_type
	var current_ease = easing_type

	if movement_type == movement_types.LOOP:
		current_trans = Tween.TRANS_LINEAR
		current_ease = Tween.EASE_IN_OUT
	var ratio = Tween.interpolate_value(0.0, 1.0, tween_time, 1.0, current_trans, current_ease)
	
	_path_follower.progress_ratio = ratio
	
	target_to_move.global_position = _path_follower.global_position

	displacement = target_to_move.global_position - last_pos
	last_pos = target_to_move.global_position
