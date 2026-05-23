extends Node2D

"""
For a given triangle corresponding to world positions of volcano shape pts

This just will fill that triangle with tiles (volcano background tiles)

TODO / easy Optimization
We probably only want to pool a certain amount of tiles
and reuse them (move them ahead by a tile width from furthest player)
when the lava subsumes them (no point in rendering them anymore)

For right now, let's just fill out the whole thing
"""
@export var game_ref: Node2D
@onready var bg_tile = preload("res://VFX/volcano_background_tile/volcano_background_tile.tscn")

var level_dimenions: Vector2
var top_pt: Vector2 = Vector2.ZERO
var left_pt: Vector2 = Vector2.ZERO
var right_pt: Vector2 = Vector2.ZERO


func _ready() -> void:
	print( get_parent().name )
	level_dimenions = game_ref.get_level_dimensions()
	generate_background()
	# -- NOTE
	global_position.y += 500


func get_volcano_outline_pts() -> void:
	var x = level_dimenions.x
	var y = level_dimenions.y
	top_pt = Vector2(0.0, -y)
	left_pt = Vector2(-x/2.0, 0)
	right_pt = Vector2(x/2.0, 0)



func generate_background():
	if level_dimenions:
		get_volcano_outline_pts()
		generate_tiles()
		pass


func generate_tiles():
	var tile_size = VolcanoBackgroundTile.tile_size
	var half_offset = Vector2( tile_size.x / 2., -tile_size.y / 2.)
	
	var total_rows_height =  abs(top_pt.y - left_pt.y)
	var N_y = num_tiles_from_dist(total_rows_height,
								   tile_size.y)
	# -- starting left & right position, just the volcano left & right
	# -- points initially
	# -- but these are updated per row to be the intersectin point between
	# -- the first tile and the line connecting the left_pt to the top_pt
	# -- and the last tile and the line connecting the right_pt to the top_pt
	# -- (updated via slab algorithm)
	var p_l = left_pt
	var p_r = right_pt
	
	var ray_origin = top_pt
	var ray_dir_l = (left_pt - top_pt).normalized()
	var ray_dir_r = (right_pt - top_pt).normalized()
	
	#print(N_y)
	for j in range(N_y):
		# -- this row's number of tiles
		var row_width = abs(p_r.x - p_l.x)
		var N_x = num_tiles_from_dist(row_width, tile_size.x)
		N_x = max(1, N_x) # -- placing on tip
		
		var next_p_l = p_l
		var next_p_r = p_r
		
		assert( level_dimenions )
		for i in range(N_x):
			var tile = bg_tile.instantiate()
			add_child( tile )
			
			tile.set_level_dimensions( level_dimenions )
			var pos = p_l + half_offset + Vector2(tile_size.x * i, 0.0)
			#print(pos)
			tile.global_position = pos
			
			# -- update the next corner position (i.e. the intersection of this
			# -- tile with the left ray
			if i == 0:
				var dist = MyMathUtils.get_line_bounds_distance(ray_origin, ray_dir_l, pos, tile_size)
				if is_finite(dist):
					next_p_l = ray_origin + (ray_dir_l * dist)
			if i == N_x - 1:
				var dist = MyMathUtils.get_line_bounds_distance(ray_origin, ray_dir_r, pos, tile_size)
				if is_finite(dist):
					next_p_r = ray_origin + (ray_dir_r * dist)
		p_l = next_p_l
		p_r = next_p_r


func num_tiles_from_dist(dist: float, a_tile_dimension: float) -> int:
	return int(round(dist / a_tile_dimension))
