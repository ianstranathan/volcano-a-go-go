extends Node2D

class_name ItemManager

var item_interface: ItemInterface
var active_movement_override: MovementOverrideComponent

#----------------------------------------------------------- Inventory Variables
const INV_SIZE := 5;
@onready var inventory_item_handles: Array[int] = []
@onready var inventory_items: Array = []
var last_selected_slot: int = -1
var special_item = null

#-----------------------------------------------------------
signal item_moving_started()
signal item_moving_stopped()
# TODO clean up aiming stuff
signal item_targeted_something( pos_or_null )
signal item_ray_target_position_changed( pos: Vector2 )
#signal targeting_item_removed()
#signal targeting_item_added()
signal item_switched( keep_aiming_visual: bool )

#signal replicated_pickup_dropped(item_enum: ItemsDb.ItemNames, pos: Vector2)
#signal rollback_pickup_spawn_requested(item_enum: ItemsDb.ItemNames)

@export var player_ref: Player

func _ready():
	inventory_item_handles.resize(INV_SIZE)
	inventory_items.resize(INV_SIZE)
	
	# -- initialize items and item handles
	# -- choosing -1 to represent free slot
	for i in range(INV_SIZE):
		inventory_item_handles[i] = -1
		inventory_items[i] = null

# -- called from player
# -- this allows an item to have a process loop with the
# -- networking tick rate ( delta time )
func process_item_tick(delta: float, command: PlayerCommand):
	if is_instance_valid(item_interface):
		item_interface.tick_update(delta, command)


func pick_up(spawn_id:int,  item_lookup: ItemsDb.ItemNames) -> void:
	#if is_multiplayer_authority() or multiplayer.is_server():
	# -- either a valid index or -1
	var free_index = inventory_item_handles.find(-1)
	# -- if we don't have a valid index, we can't fit any more items -> return
	if free_index == -1:
		return
	# -- update inventory_item_handles with this item db enum to pass to inventory UI
	inventory_item_handles[free_index] = item_lookup
	
	# -- actually allocate memory / make object
	var item = ItemsDb.get_item_from_lookup(item_lookup).instantiate()
	item.name = str( ItemsDb.ItemNames.keys()[item_lookup] ) + "-" + str(spawn_id)
	# -- put it into a container to be able to be used according to the input
	# -- index (1 2 3 4 ... )
	inventory_items[free_index] = item
	#item.item_interface.item_depleted.connect( remove_item )
	
	# -- set authority to item
	var owner_id = get_parent().name.to_int()
	item.set_multiplayer_authority( owner_id )
	
	# -- some items require knowledge about the player (e.g. to alter their velocity)
	if item.has_method("set_player_ref"):
		# -- FIXME I don't like this
		item.set_player_ref(player_ref)
		
	if owner_id == multiplayer.get_unique_id():
		connect_local_signals(item)
	else:
		connect_remote_signals(item)

	# -- case We don't have anything equiped
	if !is_instance_valid(item_interface):
		last_selected_slot = 0
		equip_item_locally(last_selected_slot)

	emit_inventory_changed()

	#Play pick up audio - Global?
	if is_multiplayer_authority() and not player_ref.is_replaying:
		Events.emit_signal("play_world_sound",
							AudioDb.WorldSoundId.ITEM_PICKUP,
							global_position,0,1,
							{}
							)
	
	call_deferred("add_child", item)


func select_inventory_slot(slot_index: int) -> void:
	if (slot_index < 0 or 
		slot_index >= inventory_items.size() or
		last_selected_slot == slot_index):
		return

	last_selected_slot = slot_index
	Events.emit_signal("play_local_sound", 
						AudioDb.LocalSoundId.HOTBAR_TICK, 
						0.0, 
						randf_range(0.95, 1.2))#pitch variation
	assert(slot_index >= 0 and slot_index < INV_SIZE)
	if inventory_items[slot_index] != null:
		equip_item_locally.rpc( slot_index )
		

# --  this has to be an rpc to mirror host's version of client and client
# --  see above (select_inventory_slot)
@rpc("call_local", "authority", "reliable")
func equip_item_locally(slot_index) -> void:
	#print(multiplayer.get_unique_id())
	#print("----------------------------")
	if is_multiplayer_authority() or multiplayer.is_server():
		stop_using_item()
		item_interface = inventory_items[slot_index].item_interface
		active_movement_override = get_component(
			inventory_items[slot_index],
			func(c): return c is MovementOverrideComponent
		)
		var raycast_comp = get_component(
			inventory_items[slot_index],
			func(c): return c is RayCastItemComponent
		)
		item_switched.emit(true if raycast_comp else false)
		emit_inventory_changed()


# -- this just tells the UI which handles are taken
func emit_inventory_changed() -> void:
	if player_ref.is_multiplayer_authority():
		#print(inventory_item_handles)
		#print(last_selected_slot)
		Events.inventory_changed.emit(inventory_item_handles,
									  last_selected_slot,
									  special_item)


# -- this is being rpc'd in world_pickup_items_manager
func drop_item( slot_to_drop ) -> void:
	print(multiplayer.get_unique_id())
	print("---------------------------")
	#var is_local = 
	#var slot_to_drop = last_selected_slot if is_local else slot
	assert(slot_to_drop != null)
	
	if slot_to_drop == -1 or inventory_items[slot_to_drop] == null:
		return

	inventory_item_handles[ slot_to_drop ] = -1
	
	if multiplayer.is_server() or is_multiplayer_authority():
		var next_slot = _calculate_fallback_slot(slot_to_drop)
		if next_slot != -1 and inventory_items[next_slot] != null:
			select_inventory_slot(next_slot)
		else:
			# -- all this is normally hidden in 
			# -- select_inventory_slot |--> equip_item_locally
			last_selected_slot = -1
			item_interface = null
			active_movement_override = null
			item_switched.emit( false )
			emit_inventory_changed()

	# -- regardless of whether local or remote, we need to delete the rsc
	free_item_inventory_node( slot_to_drop )


# ------------------------------------------------------------------------ UTILS

func connect_remote_signals(item):
	connect_signals_based_on_component(item, ["movement_override"])


func connect_local_signals(item):
	connect_signals_based_on_component(item, ["raycast", "movement_override"])


func connect_signals_based_on_component(item, arr_of_signal_names):
	for component_name in arr_of_signal_names:
		var comp: Node
		var signals: Array[Signal]
		var connections_fns: Array[Callable]
		match component_name:
			"raycast":
				comp = get_component( item, func(c): return c is RayCastItemComponent)
				if comp:
					signals = [comp.intersected_something, comp.target_position_changed] #, comp.tree_exited]
					connections_fns = [func(pos_or_null): self.emit_signal("item_targeted_something", pos_or_null),
									   func(pos: Vector2): self.emit_signal("item_ray_target_position_changed", pos)]
									   #func(): emit_signal("targeting_item_removed")]
					#targeting_item_added.emit()
			"movement_override":
				comp = get_component( item, func(c): return c is MovementOverrideComponent)
				if comp:
					# -- closure around item to check if it's the last one
					var is_last_selected_item =  func(): return inventory_items[last_selected_slot] == item
					signals = [comp.movement_override_started, comp.movement_override_finished]
					connections_fns = [func(): if is_last_selected_item: self.emit_signal("item_moving_started"),
									   func(): if is_last_selected_item: self.emit_signal("item_moving_stopped")]
		if comp:
			for i in range(signals.size()):
				signals[i].connect( connections_fns[i] )


func get_component(item: Node2D, type_predicate_fn: Callable):
	var comp_arr = item.get_children().filter( func(c): return type_predicate_fn.call(c) )
	return comp_arr[0] if comp_arr.size() > 0 else null


func is_spawning_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.ITEM_SPAWNING


func is_moving_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.PLAYER_MOVING


func can_pick_up():
	return inventory_item_handles.has(-1)


func stop_using_item():
	if is_instance_valid(item_interface):
		item_interface.stop()


#func reset_inventory_vars(slot_dropped: int) -> void:
	##free_item_inventory_node( slot_dropped )
	#last_selected_slot = -1
	#item_interface = null
	#active_movement_override = null
	#item_switched.emit( false )
	#emit_inventory_changed()


# -- this guy just walks back in the slots (wrapping) until it fnids something
func _calculate_fallback_slot(dropped_slot: int) -> int:
	var arr_size = inventory_items.size()
	for i in range(1, arr_size):
		var wrapped_index = posmod(dropped_slot - i, arr_size)
		if inventory_items[wrapped_index] != null and wrapped_index != dropped_slot:
			return wrapped_index
	return -1


func free_item_inventory_node(slot: int) -> void:
	if inventory_items[slot] != null and is_instance_valid(inventory_items[slot]):
		#print(multiplayer.get_unique_id())
		#print(inventory_items[slot])
		#print("---------------------")
		inventory_items[slot].call_deferred("queue_free")
		inventory_items[slot] = null
		inventory_item_handles[ slot ]= -1


func get_current_item_data() -> Array:
	return [get_current_item_key(), last_selected_slot ]


#func get_current_item_name() -> String:
	#if last_selected_slot != -1:
		#return inventory_items[last_selected_slot].name
	#return ""

func get_current_item_key() -> int:
	var ret = -1
	if last_selected_slot != -1:
		ret = inventory_item_handles[ last_selected_slot ]
	return ret
