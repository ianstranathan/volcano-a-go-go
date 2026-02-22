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

var input_manager: LocalPlayerController
@export var player_ref: Player


# -- called from player
func use_item(used_item_pressed: bool):
	if used_item_pressed and is_instance_valid(item_interface):
		item_interface.use( )

#func _physics_process(_delta: float) -> void:
	#if is_instance_valid(item_interface):
		#if (input_manager.just_pressed_action("use_item") and item_interface.can_use()):
			#item_interface.use( )
	#else:
		#return

func pick_up(item_lookup: ItemsDb.ItemNames):
	if item_interface:
		item_interface.destroy()

	var item = ItemsDb.get_item_from_lookup(item_lookup).instantiate()
	item_interface = item.item_interface
	# -- set authority to this peer id
	var owner_id = get_parent().name.to_int()
	item.set_multiplayer_authority( owner_id )
	item.player_ref = player_ref 

	if owner_id == multiplayer.get_unique_id():
		item.input_manager = input_manager
		# -- ray signaling and everything just happens locally
		connect_local_signals(item)
	#else:
		#item.init_as_remote()
	add_child(item)

func connect_local_signals(item):
	for component_name in ["raycast", "movement_override"]:
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
				#print(comp)
				if comp:
					active_movement_override = comp
					signals = [comp.movement_override_started, comp.movement_override_finished]
					connections_fns = [func(): self.emit_signal("item_moving_started"),
									   func(): self.emit_signal("item_moving_stopped")]
		if comp:
			for i in range(signals.size()):
				signals[i].connect( connections_fns[i] )

#func pick_up( item_lookup: ItemsDb.ItemNames):
	## -- why only on the local client's player node
	## -- or the host's version of the client?
	## -- item
	#if multiplayer.is_server() or is_multiplayer_authority():
		#if item_interface:
			#item_interface.destroy()
		#
		#var item = ItemsDb.get_item_from_lookup( item_lookup ).instantiate()
		#item_interface = item.item_interface

		#for component_name in ["raycast", "movement_override"]:
			#var comp: Node
			#var signals: Array[Signal]
			#var connections_fns: Array[Callable]
			#match component_name:
				#"raycast":
					#comp = get_component( item, func(c): return c is RayCastItemComponent)
					#if comp:
						#signals = [comp.intersected_something, comp.target_position_changed, comp.tree_exited]
						#connections_fns = [func(pos_or_null): self.emit_signal("item_targeted_something", pos_or_null),
										   #func(pos: Vector2): self.emit_signal("item_ray_target_position_changed", pos),
										   #func(): emit_signal("targeting_item_removed")]
						#targeting_item_added.emit()
				#"movement_override":
					#comp = get_component( item, func(c): return c is MovementOverrideComponent)
					##print(comp)
					#if comp:
						#active_movement_override = comp
						#signals = [comp.movement_override_started, comp.movement_override_finished]
						#connections_fns = [func(): self.emit_signal("item_moving_started"),
										   #func(): self.emit_signal("item_moving_stopped")]
			#if comp:
				#for i in range(signals.size()):
					#signals[i].connect( connections_fns[i] )
#
		#if is_moving_item() or is_spawning_item():
			## NOTE TODO FIXME
			#if is_moving_item():
				#item.input_manager = input_manager
				#item.player_ref = player_ref
			#elif items_container:
				#item.items_container_ref = items_container
			#call_deferred("add_child", item)


func get_component(item: Node2D, type_predicate_fn: Callable):
	var comp_arr = item.get_children().filter( func(c): return type_predicate_fn.call(c) )
	return comp_arr[0] if comp_arr.size() > 0 else null


func stop_using_item() -> void:
	item_interface.stop()

# ------------------------------------------ small utils
func is_spawning_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.ITEM_SPAWNING

func is_moving_item() -> bool:
	return item_interface.use_mode == item_interface.ItemUseMode.PLAYER_MOVING
