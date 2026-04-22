extends Node2D

#@export var player: CharacterBody2D
#@onready var player_initial_position = player.global_position

#@export var lava: Node2D
#@export var lava_bodies_manager: Node2D

"""
It's important for your mental model to be correct
In this networking model (i.e. Godot's multiplayer's API)
Authority is per node not per peer/ machine

So, a player assigned to a peer id:
	a_player.set_multiplayer_authority(id)
will only have authority from that peer
"""

@export var player_scene: PackedScene
@export var players_container: Node2D
@export var spawn_points: Node2D
@export var pickup_items_container: Node2D
@export var spawned_items_container: Node2D


var player_data_dict:Dictionary = {} # -- id to player_data

# -- TODO

#var tickables : Array = []
# ------------------------------------------------------------------------------
@onready var ui = $CanvasLayer/Ui

func _ready():
	assert(spawn_points)
	assert(players_container)
	# -- general callback if someone joins
	#NetManager.player_info_updated.connect(_on_player_info_received)
	
	# -- on each machine
	# -- for every id in the NetManager's player_names
	#for peer_id in NetManager.player_names_by_player_id:
		#spawn_player(peer_id)
	await get_tree().create_timer(0.1).timeout
	
	print("Spawning Game with ", NetManager.player_data.size(), " players.")
	
	for id in NetManager.player_data:
		var d = NetManager.player_data[id]
		spawn_player(id, d[NetManager.KEY_NAME], d[NetManager.KEY_INDEX])
	
	NetManager.game_world = self
	
	# ------------------------------------------------------- UI hookups
	ui.game_ref = self
	
	# --------------- TEST
	$WorldGeometry/FallingPlatform.lava_ref = $WorldGeometry/Lava
	
func execute_tick( delta: float ):
	for child in $WorldGeometry.get_children():
		if child.has_method("execute_tick"):
			child.execute_tick( delta )
	
	ui.execute_tick( delta )

func _on_player_info_received(peer_id: int, _name: String, spawn_index: int):
	spawn_player(peer_id, _name, spawn_index)


# -- we're just piping this ID from the NetManager
func spawn_player(peer_id: int, _name: String, spawn_index: int):
	# -- scene name is the peer id to keep things straight
	var a_players_name = str(peer_id)
	
	# -- no duplicates (don't spawn the same id twice)
	if players_container.has_node( a_players_name ):
		return
	# -- 
	var a_player = player_scene.instantiate()
	a_player.name = a_players_name
	
	# -- Spawn index has to be deterministic
	# -- The Host must be the one to decide that
	var points_count = spawn_points.get_child_count()
	var actual_point = spawn_points.get_child(spawn_index % points_count)
	a_player.global_position = actual_point.global_position
	
	# -- assign multiplayer authority to the player before
	# -- it's added to scene tree
	# -- otherwise the controller logic breaks (remote vs local)
	NetManager.register_player_instance(peer_id, a_player)
	
	
	# -- Initialize player stuff: 
	# -- item_container, multiplayer authority, color, camera
	a_player.set_multiplayer_authority(peer_id)
	
	# --------------------------------------------- replace player color with UI
	var _col = rand_player_color( peer_id )
	a_player.color = _col
	
	# --------------------------------------------- set up data struct for UI
	var a_player_data = PlayerData.new()
	#a_player_data.is_local_player = a_player.is_multiplayer_authority()
	a_player_data.id = peer_id
	a_player_data.display_name = _name
	a_player_data.turban_color = _col
	 
	a_player_data.skin_tone = rand_skin_tone( peer_id )
	player_data_dict[peer_id] = a_player_data
	
	# ---------------------------------------------
	a_player.items_container = spawned_items_container
	if peer_id == multiplayer.get_unique_id():
		$Camera.target_initialize(a_player)
	players_container.add_child(a_player)

	# -- we need the players to spawn before running this
	$WorldEffects.initialize_recurring_player_vfx()


# ------------------------------------------------------------------------ Utils
func ordered_players_by_height() -> Array:
	"""
	Used in UI to decide relative heights of players
	sorts players by global_position.y and returns an array of their ids
	"""
	var ret = $PlayersContainer.get_children()
	# -- sort_custom sorts in place
	ret.sort_custom( func(a: Player, b: Player):
		if abs(a.global_position.y - b.global_position.y) < 1:
			# -- using id as a tie-breaker to prevent jitter
			return int(a.name) < int(b.name) 
		return (a.global_position.y < b.global_position.y))
	return ret


@onready var rng = RandomNumberGenerator.new()

func rand_player_color( seed_val: int) -> Color:
	rng.seed = seed_val + 100
	var r = rng.randf()
	var g = rng.randf()
	var b = rng.randf()
	return Color(r, g, b)


func rand_skin_tone( seed_val: int) -> int:
	rng.seed = seed_val
	return rng.randi_range(0, 4)


# -- hardcoding until someone makes a level
@export var level_x_length = 10000
@export var level_y_length = 6000

func get_level_dimensions() -> Vector2:
	return Vector2(level_x_length, level_y_length)
