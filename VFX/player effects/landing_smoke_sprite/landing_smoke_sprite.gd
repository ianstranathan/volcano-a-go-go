extends Node2D


@export var animated_sprite: AnimatedSprite2D


func _ready() -> void:
	# -- gaurentee that the animated sprite 2d is stopped
	animated_sprite.stop()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		$AnimationPlayer.play("smoke_fade")
