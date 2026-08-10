class_name ShakeInstance
extends RefCounted

var amplitude: float
var duration: float
var direction: Vector2
var ease_func: Callable
var is_looping: bool = false
var time_elapsed: float = 0.0
var _force_finished: bool = false

func _init(_amplitude: float, 
		_duration: float, 
		_direction: Vector2, 
		_ease_func: Callable,
		_is_looping):
	amplitude = _amplitude
	duration = _duration
	ease_func = _ease_func
	direction = _direction.normalized()
	is_looping = _is_looping


func update(delta: float) -> float:
	time_elapsed += delta
	if is_looping:
		time_elapsed = fmod(time_elapsed, duration)
	var t: float = clamp(time_elapsed / duration, 0.0, 1.0)
	return amplitude * ease_func.call(t)


func stop() -> void:
	if is_looping:
		is_looping = false
		time_elapsed = fmod(time_elapsed, duration) 
	else:
		_force_finished = true


func is_finished() -> bool:
	if is_looping and not _force_finished:
		return false
	return time_elapsed >= duration
