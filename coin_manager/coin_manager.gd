extends Node2D

#@export var coin_sprite: Texture
@onready var multimesh_instance: MultiMeshInstance2D = $MultiMeshInstance2D

# NOTE
var players_container_ref: Node2D
var players : Array[Player]

const step_dirs = [-1, 0, 1]

# Configuration
const CELL_SIZE: float = 256.0 # Grid cell size in pixels (e.g., 64x64)
const COLLECTION_RADIUS = 64.0
const COLLECTION_RADIUS_SQ = COLLECTION_RADIUS * COLLECTION_RADIUS
# The Grid: Vector2i(x, y) -> Array of coin indices
var grid: Dictionary = {}

# Flat arrays for fast lookup by index
var coins_list: Array[Vector2] = [] 
var coins_active: Array[bool] = []

@export var coin_path: Path2D
@export var spacing: float = 80.0 # Distance in pixels between each coin

func _ready() -> void:
	visible = true
	assert( coin_path )
	generate_coins_along_path()


func spawn_individual_mesh_coin(index: int, pos: Vector2) -> void:
	var t = Transform2D.IDENTITY.translated(pos)
	multimesh_instance.multimesh.set_instance_transform_2d(index, t)
	#if multiplayer.is_server():
	register_coin_to_grid(index, pos)


func register_coin_to_grid(index: int, pos: Vector2):
	coins_list.append(pos)
	coins_active.append(true)
	
	var cell = get_grid_cell(pos)
	
	if not grid.has(cell):
		grid[cell] = []
	
	grid[cell].append(index)

# -----------------------------------------------------------------------------

func get_grid_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / CELL_SIZE),
					floor(pos.y / CELL_SIZE))


var player_collision_shape : CollisionShape2D

var collected_players: bool = false
func execute_tick(_delta: float) -> void:
	#print("callling from coin manager")
	if !collected_players:
		collected_players = true
		for p in players_container_ref.get_children():
			players.append(p)
	
	if players and !players.is_empty():
		for player in players:
			#if !player.can_collect_coints():
				#continue
			var p_pos: Vector2 = player.global_position
			var p_cell: Vector2i = get_grid_cell(p_pos)
			
			# Check the player's cell and the 8 surrounding 2D cells
			for x_offset in step_dirs:
				for y_offset in step_dirs:
					var target_cell = p_cell + Vector2i(x_offset, y_offset)

					if not grid.has(target_cell):
						continue
					
					# Loop through only the coins in this specific cell
					for coin_index in grid[target_cell]:
						if not coins_active[coin_index]:
							continue
							
						var coin_pos: Vector2 = coins_list[coin_index]
						
						# -- broadphase, then proper capsule overlap check
						if p_pos.distance_squared_to(coin_pos) < COLLECTION_RADIUS_SQ:
							var coll_shape = player.get_node("CollisionShape2D")
							if MyMathUtils.is_circle_overlapping_capsule(
									coin_pos,
									COLLECTION_RADIUS,
									p_pos, 
									coll_shape.shape.height, 
									coll_shape.shape.radius
								):
								on_player_walked_over_coin(coin_index, player.name.to_int())


func on_player_walked_over_coin(index: int, collector_id: int) -> void:
	# -- predictively register coin pickup
	# -- broadcast that the player hit it
	# -- if the coin has already been hit
	# -- rollback that change
	collect_coin( index, collector_id)
	
	

@onready var zero_transform = Transform2D(0.0, Vector2.ZERO, 0.0, Vector2.ZERO)
func collect_coin( index: int, collector_id: int ):
	# -- remove it from our polling array
	if not coins_active[index]:
		return
	coins_active[index] = false
	
	# -- save position to do some vfx
	#var coin_global_pos: Vector2 = multimesh_instance.get_instance_transform(index).origin
	
	# -- hide it
	multimesh_instance.multimesh.set_instance_transform_2d(index, zero_transform)

# ------------------------------------------------------------------------------


#@rpc("authority", "call_local", "reliable")
#func sync_coin_collected(index: int, collector_id: int) -> void:
	#pass
	# -- collapse the scale to zero to make it invisible to the GPU
	# We pass a completely blank Transform2D or zero-scaled transform
	# -- effect juice
	#spawn_collection_fx(coin_global_pos)

	# -- update ledger for this player
	#MetaProgressionManager.award_coin(collector_id)



func generate_coins_along_path() -> void:
	var curve: Curve2D = coin_path.curve
	var path_length: float = curve.get_baked_length()
	
	# Calculate how many coins fit on this line evenly
	var coin_count: int = floor(path_length / spacing)
	
	# If the path is too short for even one coin, stop
	if coin_count == 0:
		return
		
	# Initialize the MultiMesh capacity
	var mm: MultiMesh = multimesh_instance.multimesh
	mm.instance_count = 0
	mm.use_custom_data = true
	mm.instance_count = coin_count
	mm.visible_instance_count = coin_count
	
	# -- loop through and place the coins evenly
	for i in range(coin_count):
		# Calculate the exact distance along the path for this coin
		# Adding 'spacing / 2' centers the distribution nicely along the line
		var distance: float = (i * spacing) + (spacing / 2.0)
		
		# Get the position (and optionally rotation) at this distance
		var coin_position: Vector2 = curve.sample_baked(distance)
		
		# Create a Transform2D for the MultiMesh
		var xform: Transform2D = Transform2D.IDENTITY
		xform = xform.translated(coin_position)
		
		# coins to rotate to face the direction of the curve:
		# var sample_transform = curve.sample_baked_with_rotation(distance)
		# xform = sample_transform
		
		# Apply to the multimesh
		mm.set_instance_transform_2d(i, xform)
		
		register_coin_to_grid(i, xform.origin + global_position)
		
		# -- animation offset
		# Dividing 'i' by 'coin_count' gives a smooth 0.0 to 1.0 gradient along the path.
		var anim_offset: float = float(i) / float(coin_count)
		var custom_data = Color(anim_offset, 0.0, 0.0, 0.0)
		mm.set_instance_custom_data(i, custom_data)
	
	# Clean up the path node since it's no longer needed at runtime
	#coin_path.queue_free()
