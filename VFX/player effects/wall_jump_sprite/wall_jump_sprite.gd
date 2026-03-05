extends Node2D

@onready var _texture = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.animation, $AnimatedSprite2D.frame)
@onready var pos_x_offset:float = (_texture.get_size() * $AnimatedSprite2D.scale).x / 2.

func _ready() -> void:
	$VfxEffectComponent.start = (func():
		# -- position goes neg-x if flip
		# -- otherwise pos-x
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.position.x = -40.0
			#position.x = -pos_x_offset
		else:
			$AnimatedSprite2D.position.x = 40.0
		$AnimatedSprite2D.play("default")
		)
