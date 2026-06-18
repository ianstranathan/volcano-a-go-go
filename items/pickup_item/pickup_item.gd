@tool
extends Node2D
class_name PickupItem

var spawn_id = -1
signal prediction_picked_up( id, item_enum )

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
#@onready var spawn_component: ItemSpawnComponent = $ItemSpawnComponent

func _ready() -> void:
	if Engine.is_editor_hint():
		return # Stop execution here if we are inside the editor
	
	_update_sprite_color()
	$Area2D.body_entered.connect(_on_body_entered)
	#$Area2D.body_exited.connect( _on_body_exited)

var velocity: Vector2 = Vector2.ZERO
var gravity := 980 # -- default, but should steal from player
func set_spawn_kinematics(player_kinematic_data: Array):
	global_position = player_kinematic_data[0]
	velocity = player_kinematic_data[1]
	velocity *= 0.01
	gravity = player_kinematic_data[2]


var is_resting: bool = false
var min_bounce_velocity: float = 60.0 # Velocity threshold to stop bouncing
var bounce_decay: float = 0.6

# -- we need to keep a reference to the last player it touched
# -- for when it spawns
var last_peer_that_picked_up: int
func _on_body_entered(body: Node2D) -> void:
	if body is StaticBody2D:
		last_static_body = body
		bounce_fn()
	
	var peer_id = body.name.to_int()
	if peer_id == multiplayer.get_unique_id():
		if (body is Player and
			body.can_pick_up_item() and
			visible):
			if last_peer_that_picked_up != peer_id:
				last_peer_that_picked_up = peer_id
				#predict_hide()
				prediction_picked_up.emit( spawn_id, item_lookup)
			else:
				last_peer_that_picked_up = -1

func bounce_fn() -> void:
	if is_resting:
		return
	if velocity.y < min_bounce_velocity:
		velocity = Vector2.ZERO
		is_resting = true
		return

	velocity.y = -velocity.y * bounce_decay


func toggle(b):
	last_static_body = null
	is_resting = !b
	velocity = Vector2.ZERO
	$Sprite2D.visible = b
	$Area2D.set_deferred("monitorable", b)
	$Area2D.set_deferred("monitoring", b)



var TERMINAL_FALL_SPEED = 1400

var last_static_body: StaticBody2D

func execute_tick( delta: float ) -> void:
	#print(velocity.y, " : ", gravity)
	if !$Sprite2D.visible or is_resting:
		return
	if velocity.y < TERMINAL_FALL_SPEED:
		velocity.y += gravity * delta
	global_position += (velocity * delta) + Vector2(0., (0.5 * delta * delta * gravity))
	
	if last_static_body:
		var penetration = get_penetration_depth(last_static_body)
		if penetration > 0.0:
			global_position.y -= penetration


func get_penetration_depth(body: Node2D) -> float:
	var floor_shape_node = body.get_node_or_null("CollisionShape2D")
	if not floor_shape_node or not (floor_shape_node.shape is RectangleShape2D):
		return 0.0
	var my_shape_node = $Area2D/CollisionShape2D
	if not my_shape_node or not (my_shape_node.shape is CircleShape2D):
		return 0.0
	var _radius: float = my_shape_node.shape.radius
	var floor_rect: RectangleShape2D = floor_shape_node.shape
	var floor_top_y: float = floor_shape_node.global_position.y - (floor_rect.size.y / 2.0)
	var bottom_y: float = global_position.y + _radius

	return bottom_y - floor_top_y
