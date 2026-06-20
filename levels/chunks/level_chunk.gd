@tool
extends Node2D

class_name LevelChunk


@onready var players_container_ref: Node2D
@export var coin_manager: Node2D
@export var tickable_geometry_container: Node2D
var tickable_geometry: Array
#
#
func execute_tick( delta: float ):
	if !tickable_geometry.is_empty():
		for c in tickable_geometry:
			c.execute_tick( delta )
	if coin_manager:
		coin_manager.execute_tick( delta )


@export var bottom_marker: Marker2D
@export var top_marker: Marker2D
@export var left_marker: Marker2D
@export var right_marker: Marker2D
@export var level_data: LevelChunkData

var has_started_cloud_list: Array[Player]

func _ready() -> void:
	if !Engine.is_editor_hint():
		assert(players_container_ref)
		
		if tickable_geometry_container:
			tickable_geometry = tickable_geometry_container.get_children()
		
		#var cm =  get_node_or_null("CoinManager")
		if coin_manager:
			coin_manager.players_container_ref = players_container_ref
		var cloud_start_area = get_node_or_null("CloudStart")
		if cloud_start_area:
			cloud_start_area.body_entered.connect( func(b):
				if b is Player and b not in has_started_cloud_list:
					has_started_cloud_list.append( b )
					b.start_cloud_descent())
					

# -- built-in Godot function; it triggers automatically scene is saved
# -- so, workflow is, set the markers and save
func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		bake_level_data()


func bake_level_data() -> void:
	if level_data and top_marker and bottom_marker:
		# -- path name for a packed scene
		level_data.chunk_scene_path = scene_file_path
		
		# -- level dimensions
		# -- we're enforcing that scenes are in model space => abs calc is redundant
		var height = bottom_marker.global_position.y - top_marker.global_position.y
		level_data.level_height = height
		var width = right_marker.global_position.x - left_marker.global_position.x
		level_data.level_width = width
		
		# -- spawn pts
		var spawn_points_node = get_node_or_null("SpawnPoints")
		if spawn_points_node:
			level_data.player_spawn_points = spawn_points_node.get_children().map( func(c): return c.global_position)
		
		level_data.offset_to_chunk_origin = top_marker.position.y
		
		# -- pickup items:
		var found_pickups: Array[Dictionary] = []
		var placeholder_container = get_node_or_null("PickupPlaceholders")
		if placeholder_container:
			for child in placeholder_container.get_children():
				if child is PickupEditorPlaceholder:
					found_pickups.append({
						"item_enum": child.item_enum_type,
						"position": child.position # Using local pos so it easily stacks in world coords
					})
		level_data.pickup_definitions = found_pickups
		
		# -- from docs:
		# -- For custom resources, it's recommended to call this method whenever a meaningful change occurs,
		#level_data.emit_changed()
		#var save_path = "res://levels/level_data_rscs/" + name.to_snake_case() + "_data.tres"
		#ResourceSaver.save(level_data)
		#print("Baked level height, width and spawn points")
		var save_path = "res://levels/level_data_rscs/" + name.to_snake_case() + "_data.tres"
		var error = ResourceSaver.save(level_data, save_path)

		if error == OK:
			print("Successfully baked and saved to: ", save_path)
		else:
			push_error("Failed to save resource! Error code: ", error)


#func get_height() -> float:
	## Fallback: If the @onready variable hasn't been initialized yet, 
	## fetch it manually using get_node()
	#var b_marker = bottom_marker if bottom_marker else get_node_or_null("BottomMarker")
	#var t_marker = top_marker if top_marker else get_node_or_null("TopMarker")
	#
	#if b_marker and t_marker:
		## Distance between top and bottom markers gives you the absolute height, 
		## regardless of where the root chunk origin (0,0) is placed.
		#return abs(t_marker.position.y - b_marker.position.y)
	#elif b_marker:
		## If you only want to use the bottom marker relative to the chunk origin
		#return abs(b_marker.position.y)
	#else:
		#push_error("Markers are missing during get_height() execution!")
		#return 1000.0 # Secure fallback height so the game doesn't crash


#func _get_configuration_warnings() -> PackedStringArray:
	#if not level_data:
		#return ["Please assign a LevelData resource."]
	#if not top_marker or not bottom_marker:
		#return ["Please assign both Top and Bottom Marker2D nodes."]
	#return []
