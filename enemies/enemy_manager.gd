extends Node2D

"""
Needs to pool enemies between chunks
maintains the list of enemies that need to execute_tick()
keeps the hot ticking path as simple as possible.
"""

"""



"""


#var next_id: int = 0
##var enemies: Array[DynamicObject] = []
#var id_2_index: Array[int] = []
#var ticking_enemies: Array[DynamicObject] = []
#var tick_index_of_object: Dictionary = {}

@onready var children = get_children()

func execute_tick( delta : float):
	for c in children:
		c.execute_tick( delta )
