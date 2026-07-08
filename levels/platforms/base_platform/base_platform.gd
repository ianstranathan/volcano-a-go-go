@tool
extends Node2D
class_name BasePlatform

#signal collision_dimensions_changed(extents: Vector2)

@onready var sync_component: SpriteCollisionSync = $SpriteCollisionSync

@onready var tickables: Array = get_children().filter( func(c):
	return c.has_method("execute_tick"))

# --backing variable to hold the value before @onready nodes exist
var _coll_extents: Vector2 = Vector2(50, 50)

@export var coll_extents: Vector2:
	set(value):
		_coll_extents = value
		if is_node_ready() and sync_component:
			sync_component.coll_extents = value  # forward to child
			#collision_dimensions_changed.emit(value)
	get:
		if sync_component:
			return sync_component.coll_extents
		return _coll_extents

var _sprite_2_coll_factor :float = 1.0
@export var sprite_2_coll_factor: float:
	set(value):
		_sprite_2_coll_factor = value
		if is_node_ready() and sync_component:
			sync_component.sprite_2_coll_factor = value  # forward to child
			#print(sync_component.sprite_2_coll_factor)
			#collision_dimensions_changed.emit(value)
	get:
		return _sprite_2_coll_factor


func _ready() -> void:
	if sync_component:
		sync_component.coll_extents = _coll_extents
		sync_component.sprite_2_coll_factor = _sprite_2_coll_factor

func execute_tick(delta: float):
	for c in tickables:
		c.execute_tick(delta)
