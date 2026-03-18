extends Node2D

signal item_depleted

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


func _ready() -> void:
	assert(item_interface)

	if is_multiplayer_authority() or multiplayer.is_server():
		ray_interface.initialize_ray( max_deploy_distance )
	#
	ray_interface.global_rotation = -PI/ 2.0
	# ---------------------------------------------- item interface
	item_interface.tick_update_fn = tick_update
	item_interface.stopped.connect( func(): pass)
	item_interface.destroyed.connect( func(): pass)


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
		r.global_position = _global_pos)
		
	item_interface.depleted()
