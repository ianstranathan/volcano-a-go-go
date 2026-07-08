extends Node

"""
We're kinda enforcing that all shaders have a 'source_col' uniform
"""
# Backing variables for setters
var _color: Color = Color(0.867, 0.0, 0.632, 1.0)

@export var sprite: Sprite2D

func _enter_tree() -> void:
	_apply_color()


func _apply_color() -> void:
	var parent = get_parent()
	if not parent: 
		return
	
	# Look for a sprite child in the parent platform
	sprite = parent.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.material.set_shader_parameter("source_col", _color)


@export var color: Color:
	set(value):
		_color = value
		if sprite and sprite.material:
			sprite.material.set_shader_parameter("source_col", _color)
	get:
		return _color
