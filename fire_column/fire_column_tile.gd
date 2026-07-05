extends Sprite2D

@export var tile_size: Vector2 = Vector2(2048, 2048)

func _ready() -> void:
	var _sprite_size = GeneralUtils.sprite_size( self )
	# -- scale sprite to fit tile size
	scale =  tile_size / _sprite_size
