extends Node2D

# Contiguous data for cache-friendly iteration
var psuedo_children: Array[Node2D] = []
# Sparse Array: ID (index) -> Position in psuedo_children (value)
var id_to_index_map: PackedInt32Array = []
# Stack of IDs that were destroyed and are ready for reuse
var free_ids: Array[int] = []
var _next_id: int = 0

func _ready() -> void:
	Events.item_spawned.connect(spawn_item)


func _grow_id_map(target_size: int):
	var old_size = id_to_index_map.size()
	if target_size <= old_size:
		return
	id_to_index_map.resize(target_size)
	for i in range(old_size, target_size):
		id_to_index_map[i] = -1


func spawn_item(item_key: ItemsDb.ItemNames, fn:Callable) -> int:
	var _item = ItemsDb.get_item_from_lookup(item_key).instantiate()
	
	# --- ID ACQUISITION ---
	var current_id: int
	if not free_ids.is_empty():
		current_id = free_ids.pop_back()
	else:
		current_id = _next_id
		_next_id += 1
		# Only grow if we are making a brand new ID
		if current_id >= id_to_index_map.size():
			_grow_id_map(current_id + 100)
	
	# --------------
	# NOTE !!!!!!!! get_meta("sync_id") to kill then
	_item.set_meta("sync_id", current_id)
	
	var new_index = psuedo_children.size()
	psuedo_children.append(_item)
	id_to_index_map[current_id] = new_index
	
	fn.call( _item )
	add_child(_item)
	return current_id


func destroy_spawned_item(id: int):
	# Safety check
	if id < 0 or id >= id_to_index_map.size() or id_to_index_map[id] == -1:
		return
	
	var target_idx = id_to_index_map[id]
	var last_idx = psuedo_children.size() - 1
	
	# --- THE SWAP-TO-BACK ---
	if target_idx != last_idx:
		var last_node = psuedo_children[last_idx]
		
		# Move last node reference to the gap
		psuedo_children[target_idx] = last_node
		
		# Update the map for the node that just moved positions
		var moved_id = last_node.get_meta("sync_id")
		id_to_index_map[moved_id] = target_idx
	
	# --- CLEANUP ---
	psuedo_children[last_idx].queue_free()
	psuedo_children.pop_back()
	
	# Invalidate the ID in the map and recycle it
	id_to_index_map[id] = -1
	free_ids.append(id)
