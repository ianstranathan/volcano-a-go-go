extends Node2D

# -- w
@onready var player: Player= get_parent()
@onready var MAX_METABALL_SPEED : float = player.kd.baseline_speed
@onready var METABALL_ACCEL : float = player.kd.MOV_ACCL
var metaball_edge := 0        # 0=top, 1=right, 2=bottom, 3=left
var metaball_t := 0.0         # 0..1 position along current edge
var metaball_speed := 0.0
var metaball_platform : MetaballPlatformComponent
var rect_size: Vector2
var perimeter: float
var perimeter_distance := 0.0
var metaball_platform_ref # -- metaball component


func initialize_metaball_state(contact_pt: Vector2, platform_ref: MetaballPlatformComponent):
	metaball_platform_ref = platform_ref
	perimeter_distance = project_point_to_perimeter( contact_pt )
	metaball_speed = player.velocity.length()
	rect_size = metaball_platform_ref.get_rect_size()
	perimeter = (rect_size.x + rect_size.y) * 2.0


func increment_perimeter(delta: float, incr_rate: float) -> Vector2:
	# -- incr_rate is just the max input from the player (x, y)
	metaball_speed = move_toward(
		metaball_speed,
		incr_rate * MAX_METABALL_SPEED,
		METABALL_ACCEL * delta
	)
	perimeter_distance += metaball_speed * delta
	perimeter_distance = wrapf(
		perimeter_distance,
		0.0,
		perimeter
	)
	return perimeter_to_world()


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


func perimeter_to_world():
	return metaball_platform.get_platform_transform() * perimeter_to_local()



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


func perimeter_normal():
	var d = perimeter_distance
	var w = rect_size.x
	var h = rect_size.y

	if d < w:
		return Vector2.UP

	d -= w

	if d < h:
		return Vector2.RIGHT

	d -= h

	if d < w:
		return Vector2.DOWN

	return Vector2.LEFT


# -- finds the nearest edge and converts it into a distance around the perimeter
func project_point_to_perimeter(point):
	var local = metaball_platform.get_platform_transform().affine_inverse() * point
	var hw = rect_size.x * 0.5
	var hh = rect_size.y * 0.5

	var distances = [
		abs(local.y + hh),   # top
		abs(local.x - hw),   # right
		abs(local.y - hh),   # bottom
		abs(local.x + hw)    # left
	]

	var edge = 0
	var best = distances[0]

	for i in range(1, 4):
		if distances[i] < best:
			best = distances[i]
			edge = i

	match edge:
		0:
			return clamp(local.x + hw, 0.0, rect_size.x)

		1:
			return rect_size.x + clamp(local.y + hh, 0.0, rect_size.y)

		2:
			return rect_size.x + rect_size.y + clamp(hw - local.x, 0.0, rect_size.x)

		_:
			return rect_size.x * 2 + rect_size.y + clamp(hh - local.y, 0.0, rect_size.y)
