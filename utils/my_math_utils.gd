extends Node

class_name MyMathUtils

## -- if you're curious, this is the slab method
# -- Slab Method, Kay and Kajiya
# -- https://ianstranathan.github.io/html/Demos/ray-box-intersection/

## Checks intersection between a ray and an aabb
static func intersect_line_bounds(ray_origin: Vector2, 
								  ray_dir: Vector2, 
								  box_pos: Vector2, 
								  box_size: Vector2) -> bool:
	var inv_dir = Vector2(1.0 / ray_dir.x, 1.0 / ray_dir.y)
	
	# Calculate the bounds manually (min and max corners)
	var box_min = box_pos
	var box_max = box_pos + box_size

	var t1 = (box_min.x - ray_origin.x) * inv_dir.x
	var t2 = (box_max.x - ray_origin.x) * inv_dir.x
	var t3 = (box_min.y - ray_origin.y) * inv_dir.y
	var t4 = (box_max.y - ray_origin.y) * inv_dir.y

	var t_min = max(min(t1, t2), min(t3, t4))
	var t_max = min(max(t1, t2), max(t3, t4))

	return t_max >= max(0.0, t_min)


## Returns distance to hit, or INF if no hit
static func get_line_bounds_distance(ray_origin: Vector2, 
									 ray_dir: Vector2, 
									 box_pos: Vector2, 
									 box_size: Vector2) -> float:
	# Pre-calculate reciprocals
	var inv_dir_x = 1.0 / ray_dir.x
	var inv_dir_y = 1.0 / ray_dir.y
	
	# Calculate half-extents
	var half_size = box_size * 0.5
	
	# Define the min and max corners relative to the center
	var b_min = box_pos - half_size
	var b_max = box_pos + half_size

	# X-axis slab
	var t1 = (b_min.x - ray_origin.x) * inv_dir_x
	var t2 = (b_max.x - ray_origin.x) * inv_dir_x
	
	# Y-axis slab
	var t3 = (b_min.y - ray_origin.y) * inv_dir_y
	var t4 = (b_max.y - ray_origin.y) * inv_dir_y

	# Standard Slab Method logic
	var t_min = max(min(t1, t2), min(t3, t4))
	var t_max = min(max(t1, t2), max(t3, t4))

	# Check for valid intersection
	if t_max >= max(0.0, t_min):
		return t_min
	
	return INF
