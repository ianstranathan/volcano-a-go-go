@tool
extends Node2D

@export var refresh := false:
	set(value):
		_update_line()
		refresh = false

@onready var path: Path2D = $Path2D
@onready var line: Line2D = $Line2D

var _last_points: PackedVector2Array

func _ready() -> void:
	if !Engine.is_editor_hint():
		_update_line()


func _update_line() -> void:
	if not is_instance_valid(path) or not is_instance_valid(line):
		return

	var curve := path.curve

	if curve == null:
		line.clear_points()
		return

	var points := curve.get_baked_points()

	if points != _last_points:
		line.points = points
		_last_points = points
