extends Node2D

@onready var children = get_children()

func execute_tick( delta : float):
	for c in children:
		c.execute_tick( delta )
