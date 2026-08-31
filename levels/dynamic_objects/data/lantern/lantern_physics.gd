extends Node2D

static func collision_response(_parent: CharacterBody2D,
								_dynamic_obj_profile: DynamicObjectProfile,
								collision: KinematicCollision2D,
								_delta: float):
	var normal = collision.get_normal()
	
	# Check if hitting the ground (normal pointing upwards)
	if normal.dot(Vector2.UP) > 0.7:
		_parent.velocity = Vector2.ZERO
	else:
		# Slide along walls or steep slopes instead of stopping
		_parent.velocity = _parent.velocity.slide(normal)
		var remainder = collision.get_remainder().slide(normal)
		_parent.move_and_collide(remainder)
