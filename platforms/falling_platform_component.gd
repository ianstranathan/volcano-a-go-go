extends Node2D

@onready var p = get_parent()
var velocity: Vector2 = Vector2.ZERO
var gravity = 4000
@export var TERMINAL_VEL_Y = 2000

var is_falling: bool = true

func _ready() -> void:
	assert(p and p is AnimatableBody2D)


func execute_tick(delta: float):
	if is_falling:
		var motion = (velocity * delta) + Vector2(0., (0.5 * delta * delta * gravity))
		velocity += Vector2(0., gravity * delta)
		# -- velocity verlet update
		p.global_position += motion
		velocity.y = min( velocity.y, TERMINAL_VEL_Y)


func stop_falling() -> void:
	velocity = Vector2.ZERO
	is_falling = false
