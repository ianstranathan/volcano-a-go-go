extends Node2D

func _ready() -> void:
	# ----------------------------------------- vfx component setup
	$VfxEffectComponent.start = func(_params):
		$AnimationPlayer.play("RESET")
		show()
		$AnimationPlayer.play("smoke_fade")
	$AnimationPlayer.animation_finished.connect( func(_anim_name):
		my_stop())

	# ----------------------------------------- 
	# -- make sure the model position is aligned with the edge of 
	# -- the texture being at origin
	#$AnimatedSprite2D.position.y = GeneralUtils.align_sprite_to_world_origin_offset($AnimatedSprite2D).y
	my_stop()


func my_stop():
	hide()
	$AnimationPlayer.stop()
