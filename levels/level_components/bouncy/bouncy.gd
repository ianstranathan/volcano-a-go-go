extends Node2D

var is_bouncing := false
var t := 0.0
func _ready() -> void:
	$Area2D.body_entered.connect( func(body):
		if body is Player:
			t = 0
			is_bouncing = true
			body.velocity.y = -2000.0)
	#$Area2D.body_exited.connect( func(body):
		#if body is Player and is_bouncing:

func execute_tick( delta: float) -> void:
	if is_bouncing:
		t += 1. * delta
		$Sprite2D.material.set_shader_parameter("progress", t)
		if t >= 2:
			t = 0.
			$Sprite2D.material.set_shader_parameter("progress", 0)
			is_bouncing = false
