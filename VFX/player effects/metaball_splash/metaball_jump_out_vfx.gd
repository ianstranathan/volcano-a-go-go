extends Node2D

func _ready() -> void:
	pass
	#hide()
 	
	#$MetaballSplash.finished.connect( func():
		#hide())
	$VfxEffectComponent.start = func(params):
		show()
		#var angle_offset = sign(params.dir.y) * PI/2.0
		$MetaballSplash.rotation = Vector2.RIGHT.angle_to(params.dir) + PI/2.
		$MetaballSplash.restart()
