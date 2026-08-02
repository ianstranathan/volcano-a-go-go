@tool
extends Node2D

@export var root: Node2D:
	set(v):
		root = v
		if Engine.is_editor_hint() and is_node_ready():
			make_fire_column()

@export var apply: bool = false:
	set(v):
		if Engine.is_editor_hint() and root:
			make_fire_column()
			
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Runtime and initial scene load entry point
	make_fire_column()


func make_fire_column():
	# Guard clause: Exit if children/nodes aren't ready yet
	if not is_node_ready():
		#print("returning yo 1")
		return
		
	if not root:
		#print("returning yo 2")
		return
		
	var chunk := root as LevelChunk
	if not chunk or not chunk.level_data:
		#print("returning yo 3")
		return
		
	var level_chunk_data = chunk.level_data
	
	if not sprite:
		#print("returning yo 4")
		return
		
	var texture_base_size: Vector2 = sprite.texture.get_size()
	if texture_base_size == Vector2.ZERO:
		#print("returning yo 5")
		return
		
	var target_size := Vector2(1000, level_chunk_data.level_height)
	
	sprite.scale = target_size / texture_base_size
	var mid_point_y: float = (level_chunk_data.level_height / 2.0) + level_chunk_data.offset_to_chunk_origin
	sprite.position = Vector2(0., mid_point_y)
	
	if sprite.material:
		sprite.material.set_shader_parameter("sprite_size", target_size)
		
	print(sprite.material)
	print(target_size)
	
