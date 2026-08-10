
extends Resource
class_name ShakeData

@export var duration: float = 0.2
@export var amplitude: float = 15.0
@export var frequency: float = 30.0
@export var falloff_curve: Curve
@export var randomness = 0.25;
@export var direction: Vector2 = Vector2.ZERO

func _init(dir: Vector2) -> void:
	direction = dir
