@tool
extends StaticBody2D

@export var coll_polygon2d: CollisionPolygon2D
@export var curve_to_copy: Path2D
@export var height_marker: Marker2D
@export var generate: bool = false:
	#get:
		#return health # Triggered when reading the variable
	set(value):
		generate = value
		generate_geometry()


func generate_geometry():
	# 1. Get the curved points array
	var curved_points: PackedVector2Array = curve_to_copy.curve.get_baked_points()
	
	# 2. Calculate your bottom corner coordinates
	var bottom_right_pt = Vector2(curved_points[-1].x, height_marker.global_position.y)
	var bottom_left_pt = Vector2(curved_points[0].x, height_marker.global_position.y)
	curved_points.append(bottom_right_pt)
	curved_points.append(bottom_left_pt)
	coll_polygon2d.polygon = curved_points

#func generate_geometry():
	#var curved_points: PackedVector2Array = curve_to_copy.get_baked_points()
	#
	## -- curved points
	#var bottom_right_pt = Vector2(curved_points[-1].x, height_marker.global_position.y)
	#var bottom_left_pt = Vector2(curved_points[0].x, height_marker.global_position.y)
	#
	#coll_polygon2d.polygon = local_polygon_points
