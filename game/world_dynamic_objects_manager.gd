extends Node2D

"""
This just takes in a bunch of dynamic item definitions based on level
chunk data

world_dynamic_objects_manager.load_dynamic_objects_from_level_chunks(
		world_level_manager.get_all_dynamic_object_definitions()
	)

and puts them on this

"""
var dynamic_object_scene: PackedScene= preload("res://levels/dynamic_objects/dynamic_object.tscn")

var id_to_index: Array[int]
var next_id = 0


func load_dynamic_objects_from_level_chunks( all_dynamic_object_definitions: Array[Dictionary] ):
	var s = all_dynamic_object_definitions.size()
	id_to_index.resize(s)
	id_to_index.fill(-1)

	# -- for all the pickup items that in scene, we need to tag them
	for i in range(s):
		var c = dynamic_object_scene.instantiate()# all_dynamic_object_definitions[i] # get_child( i )
		c.dynamic_object_type = all_dynamic_object_definitions[i].get("dynamic_object_type")
		call_deferred("add_child", c)
		c.set_deferred("global_position", 
					   all_dynamic_object_definitions[i].get("global_position"))
		assert( c.spawn_id == -1, "incorrectly initialized pickup item" )
		c.spawn_id = next_id
		# -- map from ids to indices in active_pickups
		id_to_index[next_id] = i
		next_id += 1
		# --
		#c.prediction_picked_up.connect( on_authority_player_walked_over_pickup )
		#active_pickups[i] = c
