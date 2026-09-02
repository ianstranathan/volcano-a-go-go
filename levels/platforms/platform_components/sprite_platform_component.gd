@tool
extends Node2D

class_name SpritePlatformComponent

@export var base_platform: BasePlatform:
	set(_p):
		base_platform = _p


@export var sprite_texture: Texture:
	set(t):
		sprite_texture = t
		apply_texture( t )


func apply_texture(t: Texture):
	if base_platform.is_node_ready():
		var s  = base_platform.get_node("Sprite2D")
		s.texture = t
