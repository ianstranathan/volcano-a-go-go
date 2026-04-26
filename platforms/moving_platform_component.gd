extends Node2D

#@export var _root_node: Node2D
@export var target_to_move: AnimatableBody2D

# Higher modularity: Control speed, direction, and state from the inspector
@export var speed: float = 200.0
@export var is_active: bool = true

var _path_follower: PathFollow2D

var _time = 0.0
func execute_tick(delta: float):
	if not is_active or not _path_follower or not target_to_move:
		return
	_time += delta
	var t = 0.5 * (cos(0.09 * _time) + 1.0)
	_path_follower.progress_ratio = t
	target_to_move.global_position = _path_follower.global_position
