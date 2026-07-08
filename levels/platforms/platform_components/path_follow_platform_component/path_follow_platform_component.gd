extends Path2D
class_name PathFollowPlatformComponent

"""
Small utility class to make setting platform paths more ergonomic
"""
#var is_uncoupled: bool = false
#@export var _root: PathsContainer

#func _ready() -> void:
	#if Engine.is_editor_hint(): 
		#return
	#_uncouple_from_parent.call_deferred()


#func _uncouple_from_parent() -> void:
	#var original_global_transform = global_transform
	#get_parent().remove_child(self)
	#_root.add_child(self)
	#global_transform = original_global_transform
	#is_uncoupled = true

func set_progress_ratio(r: float) -> void:
	$PathFollow2D.progress_ratio = r

func set_loop(b: bool) -> void:
	$PathFollow2D.loop = b

func get_path_global_position() -> Vector2:
	return $PathFollow2D.global_position
