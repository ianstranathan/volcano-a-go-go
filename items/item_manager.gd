extends Node2D

class_name ItemManager

var item_interface: ItemInterface
var active_movement_override: MovementOverrideComponent
var items_container

#----------------------------------------------------------- Inventory Variables
const INV_SIZE := 5;
@onready var inventory_item_handles: Array[int] = []
@onready var inventory_items: Array = []
var last_selected_slot: int = 0
var special_item = null

#-----------------------------------------------------------
signal item_moving_started()
signal item_moving_stopped()

# TODO clean up aiming stuff
signal item_targeted_something( pos_or_null )
signal item_ray_target_position_changed( pos: Vector2 )
#signal targeting_item_removed()
signal targeting_item_added()

signal item_switched( keep_aiming_visual: bool )

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


func pick_up(item_lookup: ItemsDb.ItemNames) -> void:
	var free_index = inventory_item_handles.find(-1) # -- either a valid index or -1
	if free_index == -1:
		return
	# -- allocate item & initialize
	inventory_item_handles[free_index] = item_lookup
	var item = ItemsDb.get_item_from_lookup(item_lookup).instantiate()
	inventory_items[free_index] = item
	#item.item_interface.item_depleted.connect( remove_item )
	
	# -- set authority to this peer id
	var owner_id = get_parent().name.to_int()
	item.set_multiplayer_authority( owner_id )
	
	# -- some items require knowledge about the player (e.g. to alter their velocity)
	if item.has_method("set_player_ref"):
		# -- FIXME
		item.set_player_ref(player_ref)
		
	if owner_id == multiplayer.get_unique_id():
		connect_local_signals(item)
	else:
		connect_remote_signals(item)

	call_deferred("add_child", item)
	
	if !is_instance_valid(item_interface):
		equip_item_at.rpc(free_index)
	emit_inventory_changed()


@rpc("call_local", "any_peer", "reliable")
func equip_item_at(slot_index) -> void:
	if is_multiplayer_authority() or multiplayer.is_server():
		# -- switch where the interface is pointing and do some visual indication or something
		stop_using_item()
		item_interface = inventory_items[slot_index].item_interface
		# -- TODO FIXME NOTE this is not good, get the components in a less dumb way
		active_movement_override = get_component( inventory_items[slot_index], func(c): return c is MovementOverrideComponent)
		var raycast_comp = get_component( inventory_items[slot_index], func(c): return c is RayCastItemComponent)
		item_switched.emit(true if raycast_comp else false)
		emit_inventory_changed()


func emit_inventory_changed() -> void:
	if player_ref.is_multiplayer_authority():
		Events.inventory_changed.emit(inventory_item_handles,
									  last_selected_slot,
									  special_item)


func select_inventory_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= inventory_items.size():
		return
	# -- save some logic if you already have this selected
	if last_selected_slot == slot_index:
		return

	last_selected_slot = slot_index
	# -- only do the equip logic if there's an item
	if inventory_items[slot_index] != null:
		equip_item_at.rpc(slot_index)


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
					targeting_item_added.emit()
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


#func item_has_raycast_component( _item ): 
	#return (get_component(_item, func(c): return c is RayCastItemComponent) != null)


func stop_using_item() -> void:
	if is_instance_valid(item_interface):
		item_interface.stop()


func is_spawning_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.ITEM_SPAWNING


func is_moving_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.PLAYER_MOVING


func can_pick_up():
	return inventory_item_handles.has(-1)


@rpc("authority", "call_local")
func remove_item() -> void:
	assert( get_children().size() == 1)
	item_interface = null
