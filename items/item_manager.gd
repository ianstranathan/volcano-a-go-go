extends Node2D

class_name ItemManager

var item_interface: ItemInterface
var active_movement_override: MovementOverrideComponent
var items_container

signal item_moving_started()
signal item_moving_stopped()
signal item_targeted_something( pos_or_null )
signal item_ray_target_position_changed( pos: Vector2 )
signal targeting_item_removed
signal targeting_item_added

@export var player_ref: Player


# -- called from player
# -- this allows an item to have a process loop with the
# -- networking tick rate ( delta time )
func process_item_tick(delta: float, command: PlayerCommand):
	if is_instance_valid(item_interface):
		item_interface.tick_update(delta, command)


func pick_up(item_lookup: ItemsDb.ItemNames):
	if !can_pick_up():
		return
	var item = ItemsDb.get_item_from_lookup(item_lookup).instantiate()
	item_interface = item.item_interface
	item_interface.item_depleted.connect( remove_item )
	# -- set authority to this peer id
	var owner_id = get_parent().name.to_int()
	item.set_multiplayer_authority( owner_id )
	#item.player_ref = player_ref 
	if item.has_method("set_player_ref"):
		item.set_player_ref(player_ref)
		
	if owner_id == multiplayer.get_unique_id():
		connect_local_signals(item)
	else:
		connect_remote_signals(item)

	call_deferred("add_child", item)


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
	item_interface.stop()


func is_spawning_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.ITEM_SPAWNING


func is_moving_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.PLAYER_MOVING


func can_pick_up():
	print("printing in can pick up: ", item_interface)
	print("with authority: ", multiplayer.get_unique_id())
	return (item_interface == null)


@rpc("authority", "call_local")
func remove_item():
	assert( get_children().size() == 1)
	item_interface = null
	print("printing in remove_item: ",item_interface)
	print("with authority: ", multiplayer.get_unique_id())
	print("++++++++++++++++")
	get_child(0).queue_free()
	
