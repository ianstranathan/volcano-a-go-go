extends Node2D

"""
This is kind of a functional way to scale raycast positions
depending on the player state
Like what you would do in a shader
"""

var last_scaling_coeff: float = 1.0

func scale_raycast_positions( s: float ) -> void:
	last_scaling_coeff = s
	for c in get_children():
		c.position.y *= s


func reverse_scale_raycast_positions() -> void:
	for c in get_children():
		c.position.y /= last_scaling_coeff
	last_scaling_coeff = 1.0
