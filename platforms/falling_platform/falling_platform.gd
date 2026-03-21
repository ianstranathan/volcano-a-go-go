@tool
extends AnimatableBody2D


@onready var sync_tool = $CollSpriteMatcher

@export_group("Component Sync")
@export var sync_color: Color = Color(0.5, 0.5, 0.5, 1.0):
	set(value):
		sync_color = value
		if is_node_ready():
			sync_tool.color = value

@export var sync_extents: Vector2 = Vector2(50, 50):
	set(value):
		sync_extents = value
		if is_node_ready():
			sync_tool.coll_extents = value


var lava_ref: TheLava = null:
	set(value):
		#print("lava got set in falling platform: ", value)
		$lava_floating_component.lava_ref = value

func execute_tick( delta: float):
	$moveable_component.execute_tick( delta )
	$lava_floating_component.execute_tick( delta )
	

func get_velocity() -> Vector2:
	return $moveable_component.velocity


func _ready() -> void:
	# This is the most important part! 
	# When the game starts, force the physics/visuals to match the exported vars.
	_sync_to_body()


func _sync_to_body() -> void:
	var coll_shape = $CollisionShape2D
	if coll_shape and coll_shape.shape:
		# IMPORTANT: Make shape unique so you don't resize every instance
		if not coll_shape.shape.is_local_to_scene:
			coll_shape.shape = coll_shape.shape.duplicate()
		
		# Using .size is more reliable in Godot 4 for RectangleShape2D
		coll_shape.shape.size = sync_extents
		
	# 2. Update Sprite
	var sprite = $Sprite2D
	if sprite and sprite.texture:
		var tex_size = sprite.texture.get_size()
		sprite.scale = sync_extents / tex_size
		# Apply color
		if sprite.material:
			sprite.material.set_shader_parameter("source_col", sync_color)
