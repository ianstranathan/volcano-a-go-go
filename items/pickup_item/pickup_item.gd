@tool
extends Node2D
class_name PickupItem

enum ItemType {
	MOBILITY,
	CREATION,
	DESTRUCTION
}

# -- backing variables for editor vs non-editor
var _pickup_radius: float = 35.0
var _type: ItemType = ItemType.MOBILITY


# -- Exports
@export var item_lookup: ItemsDb.ItemNames:
	set(value):
		item_lookup = value
		_update_texture()

@export var _texture: Texture2D:
	set(value):
		_texture = value
		if sprite:
			sprite.texture = value
			_update_sprite_scale()
	get:
		return _texture


@export var pickup_radius: float:
	set(value):
		_pickup_radius = value
		_update_collision()
		_update_sprite_scale()
	get:
		return _pickup_radius

@export var sprite: Sprite2D

@export var type: ItemType:
	set(value):
		_type = value
		_update_sprite_color()
	get:
		return _type


func _update_texture():
	_texture = ItemsDb.get_texture(item_lookup)


func _update_collision():
	var coll_shape: CollisionShape2D = get_node_or_null("Area2D/CollisionShape2D")
	if coll_shape and coll_shape.shape:
		coll_shape.shape.radius = _pickup_radius

func _update_sprite_scale():
	if not sprite or not sprite.texture:
		return
	var tex_size: Vector2 = sprite.texture.get_size()
	sprite.scale = 2.0 * Vector2(_pickup_radius, _pickup_radius) / tex_size

func _update_sprite_color():
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("src_col", color_from_type())
		
# ===============================
# Utilities
# ===============================

func color_from_type() -> Color:
	match _type:
		ItemType.MOBILITY:
			return Color(0.504, 0.214, 1.0, 1.0)
		ItemType.CREATION:
			return Color(0.788, 0.294, 0.0, 1.0)
		ItemType.DESTRUCTION:
			return Color(0.045, 0.27, 0.943, 1.0)
	return Color(0.0, 0.0, 0.0, 1.0)


@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var spawn_component: ItemSpawnComponent = $ItemSpawnComponent

func _ready() -> void:
	if Engine.is_editor_hint():
		return # Stop execution here if we are inside the editor
	assert( spawn_component != null, "no spawn component on this item")	
	_update_sprite_color()
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect( _on_body_exited)


# -- we're assuming all pickup items are in a flat children array in
# -- world pickup item manager
@onready var manager = get_parent()

# -- we need to keep a reference to the last player it touched
# -- for when it spawns
var last_player_touched: Player
func _on_body_entered(body: Node2D) -> void:
	if body.name.to_int() == multiplayer.get_unique_id():
		if (body is Player and
			body.can_pick_up_item() and
			!spawn_component.is_predicted_hidden):
			if last_player_touched != body:
				last_player_touched = body
				spawn_component.predict_hide()
				manager.predict_pickup(spawn_component.spawn_id, item_lookup)
			else:
				last_player_touched = null


func _on_body_exited(body: Node2D) -> void:
	pass
	#if body is Player and body == last_player_touched:
		#last_player_touched = null


func execute_tick( delta: float ) -> void:
	# -- fancy falling goes here
	pass


#func _on_prediction_hidden() -> void:
	## -- would be super cool for some sparklies here or some misc. juice.
	## -- (e.g. trailing particles fading out smoothly)
	#if sprite:
		#sprite.hide()


#func _on_prediction_cancelled() -> void:
	## -- host rejection
	#if sprite:
		#sprite.show()
