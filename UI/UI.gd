extends Control

@export var DEBUG: bool = true # -- networking stats overlay uses this


var game_ref
@onready var minimap_cam: Camera2D = $HudMargin/HudLayout/BottomArea/BottomRight/SubViewportContainer/SubViewport/Camera2D
var player_ref: Player

@onready var hotbar_ui: HotbarUi = $HudMargin/HudLayout/BottomArea/BottomCenter/CenterContainer/HotbarUi

@export var track: TextureRect
@export var leader_icon_bar: Control

@export var minimap_viewport: SubViewport


# -- TODO probably don't do this every tick to save some cycles as an ez heuristic
func execute_tick( _delta: float ):
	
	if game_ref:
		var ordered_players = game_ref.ordered_players_by_height()

		# -- CHANGE ME TODO NOTE FIXME
		track.update_track(ordered_players.map( func(c): return c.global_position),
						   ordered_players.map( func(c): 
							return game_ref.player_data_dict[c.name.to_int()].turban_color))
		
		leader_icon_bar.refresh_leaderboard( 
			ordered_players.map( func(c): return c.name.to_int()),
			game_ref.player_data_dict)


func _physics_process(_delta: float) -> void:
	if player_ref:
		minimap_cam.global_position = player_ref.global_position


func set_minimap_world2d( w: World2D):
	minimap_viewport.world_2d = w
	
	minimap_viewport.set_canvas_cull_mask_bit(0, false)
	minimap_viewport.set_canvas_cull_mask_bit(1, true)

	
	#debug_check_layer_hierarchy( minimap_viewport, 1)

#func ordered_players_by_height() -> Array:
	#var ret = $PlayersContainer.get_children()
	## -- sort_custom sorts in place
	#ret.sort_custom( func(a: Player, b: Player):
		#if abs(a.global_position.y - b.global_position.y) < 1:
			## -- using id as a tie-breaker to prevent jitter
			#return int(a.name) < int(b.name) 
		#return (a.global_position.y < b.global_position.y))
	#return ret
