extends Node2D
class_name WorldPickupItemsManager


# -- data structures for iterating over our execute tick function
var active_items_arr: Array[Node2D] = []
var active_items_ids_arr: Array[int] = []

# -- data structure for RPC calls -- big O(1) lookup
var active_items_dict: Dictionary = {}    # -- { id (int): Node2D }
var active_item_indices_dict: Dictionary = {} # -- { id (int): array_index (int) }

var pool: Dictionary = {}            # -- { item_key (ItemsDb.ItemName): Array[Node2D] }
var free_ids: Array[int] = []
var _next_id: int = 0


func _ready() -> void:
	# -- convert whatever system we're using in the editor to make a level
	for child in get_children():
		# -- we stamp a spawn id on this guy from our internal id count
		make_pickup_active(_next_id, child)
		_next_id += 1

# -- allow the pickup items to kinematically animation or whatever
func execute_tick(delta: float) -> void:
	var total_items: int = active_items_arr.size()
	for i in range(total_items):
		#var item: Node2D = active_items_arr[i]
		#var id: int = active_items_ids_arr[i]
		pass

# -- fired from pickup item, this just checks to make sure there's an active
# -- item associated with the id
# -- && sends request to server
func predict_pickup(spawn_id: int, item_lookup: ItemsDb.ItemNames) -> void:
	var item = active_items_dict.get(spawn_id)
	if not item: 
		return 
	request_pickup.rpc_id(1, 
						spawn_id, 
						multiplayer.get_unique_id(),
						item_lookup)


@rpc("any_peer", "call_local", "reliable")
func request_pickup(spawn_id: int, requesting_peer_id: int, item_db_key: ItemsDb.ItemNames) -> void:
	if not multiplayer.is_server(): 
		return
	# -- this is checking if the item exists on the host side
	# -- rpcs are sequential, so this should naturally handle the race between different clients
	# -- accessing the same item (i.e. whoever asks first gets it and the item no longer exists
	var item = active_items_dict.get(spawn_id)
	if not item:
		return

	#var player_node = NetManager.player_instances_by_player_id.get(requesting_peer_id)
	#destroy_spawned_item(spawn_id, item_db_key)
	host_pickup_response.rpc( requesting_peer_id, item_db_key)
	destroy_spawned_item.rpc(spawn_id, item_db_key)
	# -- distance check (is the item pickup valid)
	#if player_node:
		#var dist_squared_to_item = player_node.global_position.distance_squared_to(item.global_position)
		#var max_allowed_distance = item.pickup_radius + 15.0 # -- networking buffer fudge factor
		#if dist_squared_to_item > max_allowed_distance * max_allowed_distance:
			#print( "denied ")
			#return


@rpc("any_peer", "call_local", "reliable")
func host_pickup_response(requesting_peer_id: int, item_db_key: ItemsDb.ItemNames):
	var player_node = NetManager.player_instances_by_player_id.get(requesting_peer_id)
	if player_node:
		player_node.take_pickup_item(item_db_key)


func on_player_dropped_pickup_item(item_key: ItemsDb.ItemNames, pos: Vector2):
	request_spawn_pickup_item.rpc_id(1, item_key, pos)


@rpc("any_peer", "call_local", "reliable")
func request_spawn_pickup_item(item_key: ItemsDb.ItemNames, pos: Vector2) -> void:
	if not multiplayer.is_server(): 
		return
		
	var assigned_id: int
	if not free_ids.is_empty():
		assigned_id = free_ids.pop_back()
	else:
		assigned_id = _next_id
		_next_id += 1
	
	# Tell all clients (including local host) to activate this item
	spawn_pickup_item_authoritative.rpc(item_key, pos, assigned_id)


@rpc("authority", "call_local", "reliable")
func spawn_pickup_item_authoritative(item_key: ItemsDb.ItemNames, pos: Vector2, assigned_id: int) -> void:
	var item: Node2D = pool[item_key].pop_back()
	item.global_position = pos 
	get_item_spawn_component(item).activate()
	make_pickup_active(assigned_id, item)


@rpc("any_peer", "call_local", "reliable")
func request_destroy(id: int, item_key: ItemsDb.ItemNames) -> void:
	if not multiplayer.is_server(): 
		return
	if not active_items_dict.has(id): 
		return
	
	destroy_spawned_item.rpc(id, item_key)


@rpc("authority", "call_local", "reliable")
func destroy_spawned_item(spawn_id: int, item_key: ItemsDb.ItemNames) -> void:
	var item = active_items_dict.get(spawn_id)
	if not item: 
		return
		
	free_ids.append(spawn_id)
	# -- if the item still exists
	_unregister_item(spawn_id)
	
	# -- we shut it down on its own terms via the interface we chose
	get_item_spawn_component(item).deactivate()

	# -- does such a group of items already exist in the pool db?
	# -- if not start one
	if not pool.has(item_key):
		pool[item_key] = []
	
	# -- add the node resource to this grouping for later
	pool[item_key].append(item)


func make_pickup_active(id: int, item: Node2D) -> void:
	active_items_dict[id] = item
	active_item_indices_dict[id] = active_items_arr.size()
	active_items_arr.append(item)
	active_items_ids_arr.append(id)
	get_item_spawn_component(item).spawn_id = id


func _unregister_item(id: int) -> void:
	active_items_dict.erase(id)
	var target_idx: int = active_item_indices_dict.get(id, -1)
	if target_idx == -1:
		return
	
	var last_idx: int = active_items_arr.size() - 1
	
	if target_idx != last_idx:
		# -- get ref to last element
		var last_node: Node2D = active_items_arr[last_idx]
		var last_id: int = active_items_ids_arr[last_idx]
		# -- swap into the slot of the item being removed
		active_items_arr[target_idx] = last_node
		active_items_ids_arr[target_idx] = last_id
		active_item_indices_dict[last_id] = target_idx
	
	active_items_arr.pop_back()
	active_items_ids_arr.pop_back()
	active_item_indices_dict.erase(id)


func get_item_spawn_component(item: Node2D) -> Node:
	return item.get_node("ItemSpawnComponent")
