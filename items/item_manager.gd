extends Node2D

class_name ItemManager

var item_interface: ItemInterface
var active_movement_override: MovementOverrideComponent
var items_container

#Iventory Variables
const INV_SIZE := 5;
var inventory_items: Array = []
var selected_slot_index: int = 0
var special_item = null

signal inventory_changed(standard_items: Array, selected_index: int, special_item)
signal item_moving_started()
signal item_moving_stopped()
signal item_targeted_something( pos_or_null )
signal item_ray_target_position_changed( pos: Vector2 )
signal targeting_item_removed
signal targeting_item_added

@export var player_ref: Player

func _ready():
	inventory_items.resize(INV_SIZE)
	
# -- called from player
# -- this allows an item to have a process loop with the
# -- networking tick rate ( delta time )
func process_item_tick(delta: float, command: PlayerCommand):
	if is_instance_valid(item_interface):
		item_interface.tick_update(delta, command)


func pick_up(item_lookup: ItemsDb.ItemNames) -> void:
	#try to add to inventory
	var stored_slot := store_picked_up_item(item_lookup)
	#if inventory was full dont pick up item
	if stored_slot == -1:
		return
	#if we already have an item equip dont auto equip
	if item_interface != null:
		return
	#select and equip item if empty handed
	selected_slot_index = stored_slot
	equip_item()
	emit_inventory_changed()
	
func equip_item() -> void:
	#unequip currently equipped item if there is one
	if item_interface != null and get_child_count() > 0:
		item_interface = null
		get_child(0).queue_free()
		
	#equipped selected item
	var item_lookup = inventory_items[selected_slot_index]
	
	#needed to select an empty slot
	if item_lookup == null:
		return

	var item = ItemsDb.get_item_from_lookup(item_lookup).instantiate()
	item_interface = item.item_interface

	if not item_interface.item_depleted.is_connected(remove_item):
		item_interface.item_depleted.connect(remove_item)
	# -- set authority to this peer id
	var owner_id = get_parent().name.to_int()
	item.set_multiplayer_authority(owner_id)
	#item.player_ref = player_ref 
	if item.has_method("set_player_ref"):
		item.set_player_ref(player_ref)
		
	if owner_id == multiplayer.get_unique_id():
		connect_local_signals(item)
	else:
		connect_remote_signals(item)
		
	call_deferred("add_child", item)	
	
func store_picked_up_item(item_lookup: ItemsDb.ItemNames) -> int:
	for i in range(inventory_items.size()):
		if inventory_items[i] != null:
			continue

		inventory_items[i] = item_lookup
		emit_inventory_changed()
		return i

	return -1
	
func select_inventory_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= inventory_items.size():
		return

	if selected_slot_index == slot_index:
		return

	selected_slot_index = slot_index
	equip_item()
	emit_inventory_changed()	
	
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
					signals = [comp.intersected_something, comp.target_position_changed, comp.tree_exited]
					connections_fns = [func(pos_or_null): self.emit_signal("item_targeted_something", pos_or_null),
									   func(pos: Vector2): self.emit_signal("item_ray_target_position_changed", pos),
									   func(): emit_signal("targeting_item_removed")]
					targeting_item_added.emit()
			"movement_override":
				comp = get_component( item, func(c): return c is MovementOverrideComponent)
				if comp:
					active_movement_override = comp
					signals = [comp.movement_override_started, comp.movement_override_finished]
					connections_fns = [func(): self.emit_signal("item_moving_started"),
									   func(): self.emit_signal("item_moving_stopped")]
		if comp:
			for i in range(signals.size()):
				signals[i].connect( connections_fns[i] )


func get_component(item: Node2D, type_predicate_fn: Callable):
	var comp_arr = item.get_children().filter( func(c): return type_predicate_fn.call(c) )
	return comp_arr[0] if comp_arr.size() > 0 else null


func stop_using_item() -> void:
	if is_instance_valid(item_interface):
		item_interface.stop()


func is_spawning_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.ITEM_SPAWNING


func is_moving_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.PLAYER_MOVING


func can_pick_up():
	return inventory_items.has(null) #can pick up if any slots are null

func emit_inventory_changed() -> void:
	inventory_changed.emit(inventory_items.duplicate(), selected_slot_index, special_item)
	

@rpc("authority", "call_local")
func remove_item() -> void:
	assert( get_children().size() == 1)
	item_interface = null
	#print("remove_item:: id: ", multiplayer.get_unique_id(),
		  #", item_interface=", item_interface)
	get_child(0).queue_free()
	
	#we probably want to refactor this. this assumed the selected item is the one that is depleted
	inventory_items[selected_slot_index] = null
	emit_inventory_changed()

#E 0:00:07:085   item_manager.gd:30 @ pick_up(): Signal 'item_depleted' is already connected to given callable 'Node2D(ItemManager)::remove_item (rpc)' in that object.
  #<C++ Error>   Method/function failed. Returning: ERR_INVALID_PARAMETER
  #<C++ Source>  core/object/object.cpp:1538 @ connect()
  #<Stack Trace> item_manager.gd:30 @ pick_up()
				#NetManager.gd:274 @ sync_item_pickup()
				#pickup_item.gd:103 @ <anonymous lambda>()
