@tool
extends Path2D

class_name PlatformPath

@export var platform_scene: PackedScene
@export var component_modifier: PackedScene
@export var block_width: float = 64.0:
	set(value):
		block_width = max(1.0, value) # Avoid division by zero
		if is_node_ready():
			generate_platforms()

@export var block_height: float = 64.0

@export var make_bridge: bool = false:
	set(b):
		make_bridge = b
		if b:
			generate_platforms()

@export var blocks_should_rotate: bool = false:
	set(b):
		blocks_should_rotate = b
		if is_node_ready():
			generate_platforms()

#
func _ready() -> void:
	var platforms_arr = get_children()
	var total_length: float = curve.get_baked_length()
	var platform_count: int = max(1, roundi(total_length / block_width))
	var step_distance: float = total_length / platform_count
	if !platforms_arr.is_empty():
		for i in range(platform_count):
			var distance: float = (i + 0.5) * step_distance
			var xform: Transform2D = curve.sample_baked_with_rotation(distance)
			platforms_arr[i].transform = xform


func execute_tick(delta):
	for c in get_children():
		#print("here")
		c.execute_tick(delta)

func generate_platforms() -> void:
	if not platform_scene or curve == null:
		return

	# Clear previous instances (handles dynamic updates in tool mode)
	for child in get_children():
		child.queue_free()

	var total_length: float = curve.get_baked_length()
	if total_length == 0.0:
		return

	# -- spacing to fit evenly along the path
	var platform_count: int = max(1, roundi(total_length / block_width))
	var step_distance: float = total_length / platform_count

	# --
	for i in range(platform_count):
		# Sample offset at the center of each segment
		var distance: float = (i + 0.5) * step_distance
		
		

		var platform: Node2D = platform_scene.instantiate() as Node2D
		assert(platform is BasePlatform)
		add_child(platform)
		
		if blocks_should_rotate:
			var xform: Transform2D = curve.sample_baked_with_rotation(distance)
			platform.transform = xform
		else:
			var local_pos: Vector2 = curve.sample_baked(distance)
			platform.position = local_pos
		
		if component_modifier:
			platform.add_child(component_modifier.instantiate())
		platform.coll_extents = Vector2( block_width, block_height)
