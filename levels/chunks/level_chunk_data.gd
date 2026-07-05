class_name LevelChunkData
extends Resource

# -- this gets baked by a level chunk script
@export var level_index: int = -1
@export var level_height: float = 0.0
@export var offset_to_chunk_origin: float
@export var level_width: float = 0.0
@export var player_spawn_points: Array
@export var pickup_definitions: Array[Dictionary] = []
@export var chunk_scene_path: String
