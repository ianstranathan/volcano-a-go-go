extends Node2D
class_name LevelManager


"""
This is just a thing that
keeps a running treadmill (bookends on either side of a calculated player position
domain, i.e. where the players are, we wanna have some level above and below to give
the illusion of a continuous space) 
uses a LevelChunk class
(where a level chunk class knows how big it is)
"""

signal level_ready(spawn_points )


const LEVEL_CHUNK_DB: Dictionary = {
	0: "res://levels/chunks/level_chunk_top.tscn",
	1: "res://levels/chunks/level_chunk_bottom.tscn",
}

const BUFFER_CHUNKS: int = 1 

# --TODO
# --there are a few places where the ultimate size of the playspace
# -- is needed, so this has gotta move somewhere accessible by those thigns
const LEVEL_TOP_Y: float = -10000.0 

var chunks_to_tick: Array
var instantiated_chunks: Dictionary = {} # index -> Node instance
var chunk_idx_is_loading: Dictionary = {}
var chunk_positions: Dictionary = {}     # index -> Vector2(top_y, bottom_y)

var next_spawn_y: float = LEVEL_TOP_Y

@onready var chunk_container: Node2D = $ChunkContainer
@export var lava_ref: Node2D 
@export var player_container_ref: Node2D

var current_chunk_idx: int = 0

func execute_tick(_delta: float) -> void:
	# -- if there's a chunk waiting to load from another thread, load it
	_poll_threaded_loads()
	
	for c in chunks_to_tick:
		c.execute_tick( _delta )
	# -- we don't need to check chunk math every frame
	# -- this is just low hanging optimization / heuristic, idk what's best
	if NetManager.current_tick % 10 == 0:
		if player_container_ref.get_child_count() == 0:
			return
			
		var lava_y: float = lava_ref.lava_fn(0)
		var required_range := _calculate_required_chunk_range(lava_y)
		
		_maintain_chunks(required_range, lava_y)


func _calculate_required_chunk_range(lava_y: float) -> Vector2i:
	var min_y: float = INF  
	var max_y: float = -INF 
	
	for player in player_container_ref.get_children():
		var pos_y = player.global_position.y
		if pos_y < min_y: min_y = pos_y
		if pos_y > max_y: max_y = pos_y
	
	if max_y > lava_y:
		max_y = lava_y
		
	var target_min_idx: int = 0
	var target_max_idx: int = current_chunk_idx # Default fallback
	
	# -- which chunk indices contain the players
	for idx in chunk_positions:
		var bounds = chunk_positions[idx]
		if min_y >= bounds.x and min_y <= bounds.y:
			target_min_idx = idx
		if max_y >= bounds.x and max_y <= bounds.y:
			target_max_idx = idx

	# -- the furthest chunk reached by the lead player
	if target_max_idx > current_chunk_idx:
		current_chunk_idx = target_max_idx
		# -- do stuff maybe if the chunk increments
		#_on_current_chunk_changed(current_chunk_idx)

	# Calculate ranges based on the BUFFER_CHUNKS around our targets
	var min_chunk_idx: int = target_min_idx - BUFFER_CHUNKS
	var max_chunk_idx: int = target_max_idx + BUFFER_CHUNKS
	
	return Vector2i(
		clamp(min_chunk_idx, 0, LEVEL_CHUNK_DB.size() - 1),
		clamp(max_chunk_idx, 0, LEVEL_CHUNK_DB.size() - 1)
	)


#func _on_current_chunk_changed(new_index: int) -> void:
	#print("Players have progressed to Chunk: ", new_index)

# -- take this out
func setup_networked_level_player_connections(p: Player):
	pass

var active_chunk_idxs: Array
func _maintain_chunks(required_range: Vector2i, lava_y: float) -> void:
	for idx in range(required_range.x, required_range.y + 1):
		# -- we're mapping the positions to a floored / grid which
		# -- is what required_range is
		# -- so if the instantiated_chunks doesn't have these chunk idx / ids
		# -- load it on another thread
		if not instantiated_chunks.has(idx) and not chunk_idx_is_loading.has(idx):
			_request_chunk_load(idx)
	
	# 2. Direct iteration over active elements to avoid garbage array allocations
	# Fix: Duplicate the keys into an array or lookups safely because we erase while iterating
	#var active_keys = instantiated_chunks.keys()
	
	for idx in active_chunk_idxs:
		var chunk_bounds = chunk_positions[idx]
		
		# -- get rid of this stuff if it's completely subsumed by lava
		if lava_y < chunk_bounds.x or idx < required_range.x or idx > required_range.y:
			_unload_and_clear_chunk(idx)


func _request_chunk_load(idx: int) -> void:
	if not LEVEL_CHUNK_DB.has(idx): 
		return
	# -- load the packedscene on another thread
	# -- from docs, load_threaded_request return type is of type Error 
	# -- which is an enum, so OK
	if ResourceLoader.load_threaded_request(LEVEL_CHUNK_DB[idx], "PackedScene", false, 1) == OK:
		chunk_idx_is_loading[idx] = true


func _poll_threaded_loads() -> void:
	var active_loading_chunk_indices = chunk_idx_is_loading.keys()
	for idx in active_loading_chunk_indices:
		var scene_path = LEVEL_CHUNK_DB[idx]
		var status = ResourceLoader.load_threaded_get_status(scene_path)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed_scene = ResourceLoader.load_threaded_get(scene_path) as PackedScene
			_instantiate_chunk(idx, packed_scene)
			chunk_idx_is_loading.erase(idx)
			break
			
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Failed to load chunk at index: ", idx)
			chunk_idx_is_loading.erase(idx)
			break


func _instantiate_chunk(idx: int, packed_scene: PackedScene) -> void:
	# -- 
	var chunk_instance = packed_scene.instantiate() as LevelChunk
	# -- so, next_spawn_y starts at top of volcano and steps down by chunk height
	chunk_instance.global_position = Vector2(0, next_spawn_y)
	chunk_instance.players_container_ref = player_container_ref
	chunk_container.add_child(chunk_instance)
	
	var height = chunk_instance.level_data.level_height
	# -- what are the bounds for this chunk [next_spawn_y, next_spawn_y + however tall
	# -- this chunk is, but we're inverting the y, cause godot
	chunk_positions[idx] = Vector2(next_spawn_y, next_spawn_y - height)
	# -- increment
	next_spawn_y += height
	
	instantiated_chunks[idx] = chunk_instance
	# -- we're getting the indices / keys on this dict so we don't have
	# -- to needlessly burn cycles in _maintain_chunks
	active_chunk_idxs = instantiated_chunks.keys()
	chunks_to_tick = chunk_container.get_children()


func _unload_and_clear_chunk(idx: int) -> void:
	var chunk = instantiated_chunks.get(idx)
	if is_instance_valid(chunk):
		chunk.process_mode = PROCESS_MODE_DISABLED
		chunk.visible = false 
		chunk.queue_free()
		
	instantiated_chunks.erase(idx)
	chunk_idx_is_loading.erase(idx) # Clears it out regardless of whether it was active or loading
	chunks_to_tick = chunk_container.get_chilren()

func start_level() -> void:
	instantiated_chunks.clear()
	
	# -- no thread-load chunk 0 because the game can't start without it
	var first_chunk_scene = load(LEVEL_CHUNK_DB[0]) as PackedScene
	_instantiate_chunk(0, first_chunk_scene)
	
	var markers = instantiated_chunks[0].get_node_or_null("SpawnPoints").get_children()
	if markers:
		var marker_positions = markers.map( func(m: Marker2D):
			return m.global_position)
		level_ready.emit(marker_positions)

	# -- start loading chunk 1 in the background
	_request_chunk_load(1)
