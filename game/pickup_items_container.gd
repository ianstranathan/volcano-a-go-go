extends Node2D

"""
This is a deterministic way I'm syncing item pickups across network
Whatever procedural generation happens, we just increment the world id
and assign it to the pickup instance
"""
var pickup_items: Array = []       # -- consider pooling instead of queueing free
var free_indices: Array[int] = []  # -- instead of resizing, check if there are free indices first
var curr_world_id: int = 0

func _ready() -> void:
	# -- for now, we're manually setting the items
	pickup_items = get_children().map( func( child ): 
		# -- just initing world_id on pickup items
		child.world_id = curr_world_id
		curr_world_id += 1
		return child)
	
	# -- we don't want to do any costly array realloc
	# -- so, let's just free it at the index and then
	# -- keep track of the index and add something back in later
	Events.item_picked_up.connect( func(a_world_id: int):
		#print(multiplayer.get_unique_id())
		free_indices.append( a_world_id )
		pickup_items[ a_world_id ].queue_free())
