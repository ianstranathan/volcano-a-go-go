extends Control


# -- this just grabs the player positions * level from the game data struct
# -- and maps it according to size of the texture rect

var player_positions_uniform_arr: Array[Vector2] = [Vector2(0., -15000), Vector2(0., -15000),
									Vector2(0., -15000), Vector2(0., -15000)]
var player_colors_uniform_arr: Array[Vector3] = [Vector3(0., 0., 0.), Vector3(0., 0., 0.),
												Vector3(0., 0., 0.), Vector3(0., 0., 0.)]

var color_set = false
# TODO NOTE
# -- loops are to account for 
func update_track(ordered_arr_of_player_positions: Array, 
				  ordered_arr_of_player_colors: Array):
	if !(ordered_arr_of_player_positions.size() == player_positions_uniform_arr.size()):
		for i in ordered_arr_of_player_positions.size():
			# -- position
			var pos = ordered_arr_of_player_positions[i]
			pos.y *= -1
			player_positions_uniform_arr[i] = pos
			# -- color
			player_colors_uniform_arr[i] = Vector3(ordered_arr_of_player_colors[i].r,
												   ordered_arr_of_player_colors[i].g,
												   ordered_arr_of_player_colors[i].b)
	material.set_shader_parameter("positions", player_positions_uniform_arr)
	material.set_shader_parameter("player_cols", player_colors_uniform_arr)
#
#func set_player_cols( arr_of_player_cols: Array):
	#if !(arr_of_player_cols.size() == player_colors_uniform_arr.size()):
		#for i in arr_of_player_cols.size():
			#player_colors_uniform_arr[i] = Vector3(arr_of_player_cols[i].r,
													#arr_of_player_cols[i].g,
													#arr_of_player_cols[i].b)
	#material.set_shader_parameter("player_cols", player_colors_uniform_arr)
