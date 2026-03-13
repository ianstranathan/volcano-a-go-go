extends Node2D

# -- TODO
# -- this is really more of an interface than a component now
class_name RayCastItemComponent

# -- item manager connects to this at object instantiation time
signal intersected_something( pos_or_null )
signal target_position_changed( the_target_position: Vector2)
@onready var ray = $RayCast2D


# -- this is just being piped through by parent
func tick_update( cmd: PlayerCommand, locked=false):
	# -- 
	if !locked:
		ray.look_at(cmd.aiming_input)
	#print("ray looking at: ", cmd.aiming_input)
	emit_signal("intersected_something", get_intersection_pos())
	emit_signal("target_position_changed", global_target_pos()) 


func global_target_pos():
	return ray.to_global(ray.target_position)


func get_intersection_pos():
	if ray.is_colliding():
		return ray.get_collision_point()
	else:
		return null


func initialize_ray( ray_dist: float):
	ray.target_position = Vector2(ray_dist, 0.0)
