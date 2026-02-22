extends Node2D

func _ready() -> void:
	$VfxEffectComponent.start = func():
		show()
		$AnimatedSprite2D.frame = 0
		$AnimatedSprite2D.play("default")
		$AnimatedSprite2D.animation_finished.connect( func(): hide())
