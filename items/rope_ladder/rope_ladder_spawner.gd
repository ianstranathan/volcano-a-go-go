extends Node2D


@onready var item_key = ItemsDb.ItemNames.ROPE_LADDER
# -- move icon to UI component
@export var icon: Texture2D # UI representation of item
# -- item interface is a component
@export var item_interface: ItemInterface
@export var max_deploy_distance: float = 800 # in px

@onready var ray_interface := $RaycastItemComponent

var deployed = false
var can_deploy = false
var items_container_ref: Node2D

#emit_signal("intersected_something", get_intersection_pos())
		#emit_signal("target_position_changed", global_target_pos())
func _ready() -> void:
	assert(item_interface)
	# ---------------------------------------------- raycast interface
	# -- NOTE clean this up maybe, default to no arity?
	#ray_interface.intersected_something.connect( func(pos_or_null):
		#can_deploy = true if pos_or_null else false)
	#ray_interface.initialize_ray(max_deploy_distance, func(_r: RayCast2D): pass)
	if is_multiplayer_authority() or multiplayer.is_server():
		ray_interface.initialize_ray( max_deploy_distance )
	#
	ray_interface.global_rotation = -PI/ 2.0
	# ---------------------------------------------- item interface
	item_interface.tick_update_fn = tick_update
	item_interface.stopped.connect( func(): pass)
	item_interface.destroyed.connect( func(): pass)
	
	#item_interface.can_use_fn = func(): return !deployed and can_deploy
	#item_interface.used.connect( deploy )
	#item_interface.stopped.connect( func(): pass )
	#item_interface.destroyed.connect( func(): call_deferred("queue_free"))


func tick_update(_delta: float, cmd: PlayerCommand):
	# -- for intersection visual, locked rot = truie
	ray_interface.tick_update(cmd, true) 
	if cmd.item_use_pressed and !deployed:
		var intersection_pos = ray_interface.get_intersection_pos()
		deploy.rpc(intersection_pos)


@rpc("authority", "call_local", "reliable")
func deploy(intersection_pos: Vector2):
	deployed = true
	var _global_pos = global_position
	Events.item_spawned.emit( item_key, func(r):
		r.target = intersection_pos
		r.global_position = _global_pos
		_sync_destruction.rpc())


@rpc("authority", "call_local", "reliable")
func _sync_destruction():
	call_deferred("queue_free")
