extends Node2D

class_name MovingPlatformComponent

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

var network_id = -1
var _time = 0.0
var last_pos: Vector2
var displacement: Vector2 = Vector2.ZERO


@export var _path_follower_component: PathFollowPlatformComponent
@onready var path_length: float = _path_follower_component.get_curve().get_baked_length()

func _ready() -> void:
	assert(target_to_move)
	assert(_path_follower_component)
	
	last_pos = target_to_move.global_position
	# -- you slap this guy on an animated body, hook it up
	# -- then it will automatically be able to be found by player script
	target_to_move.add_to_group("moving_platforms")


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
	# -- icnr normalized time
	_time += delta * (speed / path_length)
	
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
	target_to_move.global_position = _path_follower_component.get_path_global_position()#global_position

	displacement = target_to_move.global_position - last_pos
	last_pos = target_to_move.global_position
