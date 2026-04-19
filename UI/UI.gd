extends Control

@export var DEBUG: bool = true # -- networking stats overlay uses this


var game_ref

@onready var hotbar_ui: HotbarUi = $HudMargin/HudLayout/BottomArea/BottomCenter/CenterContainer/HotbarUi

# -- 
@export var track: TextureRect
@export var leader_icon_bar: Control

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
