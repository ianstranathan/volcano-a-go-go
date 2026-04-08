extends Control


# TODO FIXME
# -- hard coding the vbox to have 80px separation
@onready var player_icons = $MarginContainer/VBoxContainer.get_children()

# ------------------------------------------------------------- UI specific vars
var last_known_sorted_ids: Array = []

# -- TODO
# -- obviously you shouldn't draw more icons than there are players
#var num_players: int
#func _ready() -> void:
	#Events.players_instanced.connect( func(num_players):
		#)

func _ready() -> void:
	initialize_player_icons()


func initialize_player_icons():
	assert(player_icons)
	for i in range(player_icons.size()):
		# 1,2 ... N
		player_icons[i].change_placement_number_label( i + 1 )


func refresh_leaderboard( current_sorted_ids: Array, player_data_dict: Dictionary):
	# -- we only want to do this if we have to
	if current_sorted_ids == last_known_sorted_ids:
		return
	last_known_sorted_ids = current_sorted_ids
	for i in range(min(player_icons.size(), current_sorted_ids.size())):
		var p_id = current_sorted_ids[i]
		var data = player_data_dict[p_id]
		
		player_icons[i].change_turban_color(data.turban_color)
		player_icons[i].change_icon_skin_tone(data.skin_tone)

		# -- additionally
		# -- check the local multiplayer to give highlighting to player icon
		# -- for client
