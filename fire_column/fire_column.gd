extends Node2D

@export var level_chunk_data: LevelChunkData
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var texture_base_size: Vector2 = sprite.texture.get_size()
	var target_size := Vector2( 1000, level_chunk_data.level_height)
	sprite.scale = target_size / texture_base_size
	var mid_point_y: float = (level_chunk_data.level_height / 2.0) + level_chunk_data.offset_to_chunk_origin
	sprite.position = Vector2(0., mid_point_y)
	#sprite.material.set_shader_parameter("chunk_dims", target_size)
	sprite.material.set_shader_parameter("tile_size", target_size)
