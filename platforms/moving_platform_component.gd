extends Node2D

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

func _ready() -> void:
	assert(target_to_move)
	last_pos = target_to_move.global_position
	# -- you slap this guy on an animated body, hook it up
	# -- then it will automatically be able to be found by player script
	target_to_move.add_to_group("moving_platforms")


#func execute_tick(delta: float):
	#if not is_active or not _path_follower or not target_to_move:
		#return
	#_time += delta
	#var t = 0.5 * (cos(0.09 * _time) + 1.0)
	#_path_follower.progress_ratio = t
	#target_to_move.global_position = _path_follower.global_position
#
	#displacement = target_to_move.global_position - last_pos
	#last_pos = global_position
func execute_tick(delta: float):
	# Pull variables dynamically from the parent scope
	# .get() provides safe fallbacks if the parent lacks the property
	if not target_to_move or not _path_follower or not _root:
		return

	_time += delta * (speed / path_length)

	# We match against the enum definition residing on the parent's script type
	match movement_type:
		movement_types.OSCILLATE:
			_path_follower.progress_ratio = pingpong(_time, 1.0)
		movement_types.LOOP:
			_path_follower.loop = true
			_path_follower.progress += speed * delta
			
		movement_types.MODULO:
			_path_follower.loop = false
			_path_follower.progress_ratio = wrapf(_time, 0.0, 1.0)

	target_to_move.global_position = _path_follower.global_position
	displacement = target_to_move.global_position - last_pos
	last_pos = target_to_move.global_position
