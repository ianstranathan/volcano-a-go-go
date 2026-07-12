@tool
extends Node2D
class_name MetaballPlatformComponent

"""
What's actually required to be a metaball platform?
- shader
- on area entered logic (l;ogic injection on the platforms area2d)
"""
@export var sprite_ref: Sprite2D
@export var apply: bool:
	set(v):
		apply = v
		if v:
			_apply_metaball(get_parent())
		else:
			_restore_original()


const METABALL_MATERIAL = preload(
"res://levels/platforms/platform_components/metaball_platform_component/metaball_material.tres")
var original_material: Material
var player_array: Array[Player] 
var platform_ref: AnimatableBody2D
var _coll_extents: Vector2

func _ready() -> void:
	if not Engine.is_editor_hint():
		platform_ref = get_parent()
		player_array.resize(4)
		_coll_extents = platform_ref.coll_extents
		#print("Parent is: ", p.name, " Class: ", p.get_class())
		#platform_ref.add_to_group("metaball_platforms")
		_apply_metaball(platform_ref)
		# -- 100. wasn't enough to not distort the smin, so 1000.0
		sprite_ref.material.set_shader_parameter(
				"player_rel_positions",
				[Vector2(1000.0, 1000.0), 
				 Vector2(1000.0, 1000.0), 
				 Vector2(1000.0, 1000.0), 
				 Vector2(1000.0, 1000.0)])
		var a = platform_ref.get_node("Area2D") as Area2D
		
		# -- need to make a closure to access the area2d's physics stuff
		a.body_entered.connect( make_player_entered(a) )
		a.body_exited.connect( on_player_exited )
		
var can_render_player := false

# -- closure around the dyanmic area2d
func make_player_entered(a: Area2D) -> Callable:
	return func( body ):
		if body is Player:
			add_player_to_player_arr( body )
			var space_state = get_world_2d().direct_space_state # global physics state
			var query = PhysicsShapeQueryParameters2D.new()
			var area_shape: CollisionShape2D = a.get_node("CollisionShape2D") # Adjust path to your shape
			
			query.shape = area_shape.shape
			query.transform = area_shape.global_transform
			query.collision_mask = body.collision_layer # Only check against the body's layer
			
			## 3. Restrict the query to only check collisions with this specific body
			#query.exclude = [self] 
			
			# 4. Fetch the rest info
			var rest_info = space_state.get_rest_info(query)
			
			if rest_info.has("point"):
				var collision_point = rest_info["point"]
				print("TRANSITIONING TO META")
				#print("Exact collision point: ", collision_point)
				body.transition_to_metaball(collision_point, platform_ref)


func on_player_exited( body ):
	if body is Player:
		null_player_at_idx( body )
#func make_player_exited(a) -> Callable:
	#return func( body ):
		#if body is Player:
			


func _exit_tree() -> void:
	_restore_original()


func _apply_metaball(p: AnimatableBody2D) -> void:
	#var p = get_parent()
	if p:
		p.sprite_2_coll_factor = 2.0
		var s = p.get_node_or_null("Sprite2D")
		if s and s is CanvasItem:
			if not original_material:
				original_material = s.material
			
			# -- Duplicate material
			var m : ShaderMaterial = METABALL_MATERIAL.duplicate()
			m.set_shader_parameter("coll_extents", p.coll_extents)
			s.material = m
			sprite_ref = s


func get_rect_size() -> Vector2:
	return platform_ref.coll_extents


func get_platform_transform() -> Transform2D:
	return platform_ref.transform

func null_player_at_idx(p: Player):
	var _idx = player_2_idx.get(p.name)
	if _idx != null:
		player_array[_idx] = null
		player_2_idx.erase(p.name)

var idx = 0
var player_2_idx = {}
func add_player_to_player_arr(p: Player):
	if player_2_idx.has(p.name):
		player_array[player_2_idx[p.name]] = null
	
	player_array[idx] = p
	player_2_idx[p.name] = idx
	
	idx = wrapi(idx + 1, 0, 4)
	can_render_player = true
	
#func null_player_at_idx( p : Player):
	#var _idx = player_2_idx.get(p.name)
	#if _idx:
		#player_array[_idx] = null
#
#var idx = 0
#var player_2_idx = {}
#func add_player_to_player_arr( p: Player):
	##print(idx)
	#player_array[idx] = p
	#player_2_idx[ p.name ] = idx
	#idx += 1
	#idx = wrapi(idx, 0, 4)
	#can_render_player = true
	##print(player_array)

# -- we can do the shader stuff in a faster processing loop
# -- as it's purely visual
func _process(_delta: float) -> void:
	# -- so, get the relative positions
	# -- then get their normalized value
	if not Engine.is_editor_hint():
		if sprite_ref and can_render_player:
			var rel_positions = player_array.map( 
				func(p:Player):
					if p:
						return (p.global_position - platform_ref.global_position)
					else:
						# -- just something really far away to not affect image
						return Vector2(1000., 1000.))
			#print(rel_positions)
			sprite_ref.material.set_shader_parameter(
				"player_rel_positions",
				rel_positions)


func _restore_original() -> void:
	var s = get_parent().get_node_or_null("Sprite2D")
	if s is CanvasItem and s.material != original_material:
		s.material = original_material
		sprite_ref = null
		can_render_player = false

# -- NOTE I handed this off to the shader as I was already passing coll_extents
# -- just keeping here to remind myself

# -- this is just giving the normalized value of the player in the shader
# -- with the constraint it has to be 0.5 at rel_pos.xy == _coll_extents.xy
# -- (where rel_pos is the relative position vecotr between the platform and the player)
#func normalize_for_shader_sdf(rel_pos: Vector2):
	#return 0.5 * (rel_pos / _coll_extents)
	
