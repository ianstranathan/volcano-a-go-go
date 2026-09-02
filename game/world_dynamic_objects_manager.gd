extends Node2D

# -- TODO
# -- state sychronization has to happen periodically
# -- so, like when it goes to sleep or is woken up
# -- additionally, if a lot of stuff happens away from player
# -- that needs to be synced, so if free, timer every 5 secs or something

"""
Manages dynamic objects that can move between level chunks.

e.g.
- rocks
- special carried items (oddball, lantern, metaball totem or whatever)

Dynamic objects do not know about this manager.

A DynamicObject emits:
	- woke_up
	- put_to_sleep

The manager listens to those signals and maintains the list of
objects that need to execute_tick().

This keeps the hot ticking path as simple as possible.
"""


var dynamic_object_scene: PackedScene = preload(
	"res://levels/dynamic_objects/dynamic_object.tscn"
)

var next_id: int = 0
var dynamic_objects: Array[DynamicObject] = []
# spawn_id -> index into dynamic_objects
var id_2_index: Array[int] = []

var ticking_objects: Array[DynamicObject] = []

# DynamicObject -> index in ticking_objects.
# Used to remove an object in O(1) using swap/remove.
var tick_index_of_object: Dictionary = {}


"""
See game script:
	world_dynamic_objects_manager.load_dynamic_objects_from_level_chunks(
		world_level_manager.get_all_dynamic_object_definitions()
	)
""" 
func load_dynamic_objects_from_level_chunks(all_dynamic_object_definitions: Array[Dictionary]) -> void:
	for definition in all_dynamic_object_definitions:
		var object: DynamicObject = dynamic_object_scene.instantiate()
		
		var object_index := dynamic_objects.size()
		var spawn_id := next_id

		next_id += 1
		object.spawn_id = spawn_id
		
		# -- get the same profile from our pseudo database
		object.dynamic_object_profile = DynamicObjectsDb.get_profile(
			definition.get("dynamic_object_type"))
		
		dynamic_objects.push_back(object)

		if id_2_index.size() <= spawn_id:
			id_2_index.resize(spawn_id + 1)

		id_2_index[spawn_id] = object_index

		object.woke_up.connect(_on_object_woke_up)
		object.put_to_sleep.connect(_on_object_put_to_sleep)
		#object.got_grabbed.connect( on_object_got_grabbed )
		
		#add_child(object)
		#object.global_position = definition.get("global_position")
		call_deferred("add_child", object)
		object.set_deferred("global_position", 
					   definition.get("global_position"))
		

		# Dynamic objects start active
		add_ticking_object(object)


#@rpc("reliable", "call_remote")
#func remote_get_grabbed( id: int):
	## -- so, the host is simulating the remote already
	## -- just like in items, we shouldnt' need to manually tell
	## -- the corresponding remote player to pick up the object
	#if !multiplayer.is_server():
		## -- get player ref on this machine
		## -- force it to take this object as a reference
		#NetManager.player_instances_by_player_id.get(id).grab_dynamic_object( self )
		#
#func on_object_got_grabbed( obj: DynamicObject, calling_id: int ):
	## -- scene tree might mutate (dynamic objects will go out of scope eventually / lava w/e )
	## -- 
	#pass

func get_object(spawn_id: int) -> DynamicObject:
	if spawn_id < 0 or spawn_id >= id_2_index.size():
		return null

	var object_index := id_2_index[spawn_id]

	if object_index < 0 or object_index >= dynamic_objects.size():
		return null

	return dynamic_objects[object_index]


func _on_object_woke_up(object: DynamicObject) -> void:
	add_ticking_object(object)


func _on_object_put_to_sleep(object: DynamicObject) -> void:
	remove_ticking_object(object)


func add_ticking_object(object: DynamicObject) -> void:
	if tick_index_of_object.has(object):
		return

	tick_index_of_object[object] = ticking_objects.size()
	ticking_objects.push_back(object)


func remove_ticking_object(object: DynamicObject) -> void:
	if not tick_index_of_object.has(object):
		return

	var tick_index: int = tick_index_of_object[object]
	var last_index := ticking_objects.size() - 1

	if tick_index != last_index:
		var last_object := ticking_objects[last_index]

		ticking_objects[tick_index] = last_object
		tick_index_of_object[last_object] = tick_index

	ticking_objects.pop_back()
	tick_index_of_object.erase(object)



func execute_tick(delta: float) -> void:
	for object in ticking_objects:
		object.execute_tick(delta)


func is_object_ticking(object: DynamicObject) -> bool:
	return tick_index_of_object.has(object)


func get_dynamic_object_count() -> int:
	return dynamic_objects.size()


func get_ticking_object_count() -> int:
	return ticking_objects.size()



"""
This is called by the host (callback on dynamic object state change)
either sleeping or active
"""
@rpc("authority", "call_remote", "reliable")
func rpc_sync_state(p_spawn_id: int, p_pos: Vector2, p_vel: Vector2, p_state: DynamicObject.DynamicObjectState) -> void:
	var obj = get_object(p_spawn_id)
	if not obj:
		return
	
	# Case: sleeping
	if p_state == DynamicObject.DynamicObjectState.SLEEPING:
		obj.global_position = p_pos
		obj.velocity = Vector2.ZERO
		obj.set_state(p_state)
		return

	# Fall, wurde aufgewecht
	var distance_drift = obj.global_position.distance_to(p_pos)
	if distance_drift > 5.0: # Threshold in pixels
		obj.global_position = obj.global_position.lerp(p_pos, 0.3)
	
	obj.velocity = p_vel
	if obj.state != p_state:
		obj.set_state(p_state)
