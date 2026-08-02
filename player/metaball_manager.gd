extends Node2D

"""
Every piece of geometry is computed in the same coordinate system until the very end
"""
# -- w
@onready var player: Player= get_parent()
@onready var MAX_METABALL_SPEED : float = player.kd.baseline_speed
@onready var METABALL_ACCEL : float = player.kd.MOV_ACCL
var metaball_edge := 0        # 0=top, 1=right, 2=bottom, 3=left
var metaball_t := 0.0         # 0..1 position along current edge
var metaball_speed := 0.0
var platform_ref : BasePlatform
var rect_size: Vector2
var perimeter: float
var perimeter_distance := 0.0


func initialize_metaball_state(contact_pt: Vector2, _platform_ref: BasePlatform):
	platform_ref = _platform_ref
	rect_size = platform_ref.coll_extents
	perimeter_distance = project_point_to_perimeter( contact_pt )
	metaball_speed = player.velocity.length()
	
	perimeter = (rect_size.x + rect_size.y) * 2.0
	
	#print("Global Contact Pt: ", contact_pt)
	#print("Platform Global Pos: ", platform_ref.global_position)
	#print("Calculated Perimeter Dist: ", perimeter_distance)

func increment_perimeter(delta: float, move_input: Vector2) -> Vector2:
	var target_speed := 0.0

	if move_input.length_squared() > 0.01:
		var tangent = perimeter_tangent()
		var alignment = move_input.dot(tangent)
		target_speed = alignment * MAX_METABALL_SPEED

	metaball_speed = move_toward(
		metaball_speed,
		target_speed,
		METABALL_ACCEL
	)

	perimeter_distance = wrapf(
		perimeter_distance + metaball_speed * delta,
		0.0,
		perimeter
	)

	# -- the caller (player) decides what coordinate space it wants.
	return perimeter_to_local()


func perimeter_to_local():
	var d = perimeter_distance
	var w = rect_size.x
	var h = rect_size.y

	var p = (w + h) * 2.0

	d = wrapf(d, 0.0, p)

	if d < w:
		return Vector2(
			-w * 0.5 + d,
			-h * 0.5
		)

	d -= w

	if d < h:
		return Vector2(
			w * 0.5,
			-h * 0.5 + d
		)

	d -= h

	if d < w:
		return Vector2(
			w * 0.5 - d,
			h * 0.5
		)

	d -= w

	return Vector2(
		-w * 0.5,
		h * 0.5 - d
	)

# -- returns the point on the rectange in the platform's local space
func perimeter_to_world():
	return platform_ref.transform * perimeter_to_local()
	#return platform_ref.transform * perimeter_to_local()



func perimeter_tangent():
	var d= perimeter_distance
	var w = rect_size.x
	var h = rect_size.y
	if d < w:
		return Vector2.RIGHT

	d -= w

	if d < h:
		return Vector2.DOWN

	d -= h

	if d < w:
		return Vector2.LEFT

	return Vector2.UP


func perimeter_normal() -> Vector2:
	var d = wrapf(perimeter_distance, 0.0, perimeter) # 
	var w = rect_size.x
	var h = rect_size.y
	#print("d is: ", d, "and w is: ", w)
	if d < w:
		#print("d < w; ", d, "; ", w)
		return Vector2.UP 
	elif d < w + h:
		#print("d < w + h; ", d, "; ", w + h)
		return Vector2.RIGHT
	elif d < (2. * w) + h:
		#print("d < (2. * w) + h; ", d, "; ", (2. * w) + h)
		return Vector2.DOWN
	#print("yee gods")
	return Vector2.LEFT          


func project_point_to_perimeter(point: Vector2) -> float:
	# Convert world point to platform local space
	#var local = platform_ref.transform.affine_inverse() * point
	#var local = platform_ref.global_transform.affine_inverse() * point
	var local = platform_ref.to_local(point)
	var hw = rect_size.x * 0.5
	var hh = rect_size.y * 0.5

	# Clamp the local point to ensure it sits exactly on/inside the rectangle boundary
	local.x = clamp(local.x, -hw, hw)
	local.y = clamp(local.y, -hh, hh)

	# Calculate distance from the local point to all 4 edges
	var dist_top = abs(local.y + hh)
	var dist_bottom = abs(local.y - hh)
	var dist_left = abs(local.x + hw)
	var dist_right = abs(local.x - hw)

	var min_dist = min(dist_top, min(dist_bottom, min(dist_left, dist_right)))

	# Match the edge based on the shortest distance and return the 1D perimeter coordinate
	if min_dist == dist_top:
		# Top Edge: traveling Left to Right. Local X goes from -hw to +hw
		return local.x + hw
		
	elif min_dist == dist_right:
		# Right Edge: traveling Top to Bottom. Local Y goes from -hh to +hh
		return rect_size.x + (local.y + hh)
		
	elif min_dist == dist_bottom:
		# Bottom Edge: traveling Right to Left. Local X goes from +hw to -hw
		return rect_size.x + rect_size.y + (hw - local.x)
		
	else:
		# Left Edge: traveling Bottom to Top. Local Y goes from +hh to -hh
		return (rect_size.x * 2.0) + rect_size.y + (hh - local.y)
