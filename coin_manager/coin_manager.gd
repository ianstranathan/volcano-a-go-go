extends Node2D

@export var coin_sprite: Texture
func _ready() -> void:
	var quadmesh = QuadMesh.new()
	# -- meshes get flipped
	# -- positive Y is down
	# -- if you make the y of the quadmesh negative, the textures appear normal
	quadmesh.size = coin_sprite.get_size() * Vector2(1, -1)
