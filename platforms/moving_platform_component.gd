extends Node2D

#@export var _root_node: Node2D
@export var target_to_move: AnimatableBody2D

# Higher modularity: Control speed, direction, and state from the inspector
@export var speed: float = 200.0
@export var is_active: bool = true

var _path_follower: PathFollow2D

var _time = 0.0
var last_pos: Vector2
var displacement: Vector2 = Vector2.ZERO


func _ready() -> void:
	assert(target_to_move)
	last_pos = target_to_move.global_position
	# -- you slap this guy on an animated body, hook it up
	# -- then it will automatically be able to be found by player script
	target_to_move.add_to_group("moving_platforms")


func execute_tick(delta: float):
	if not is_active or not _path_follower or not target_to_move:
		return
	_time += delta
	var t = 0.5 * (cos(0.09 * _time) + 1.0)
	_path_follower.progress_ratio = t
	target_to_move.global_position = _path_follower.global_position

	displacement = target_to_move.global_position - last_pos
	last_pos = global_position
