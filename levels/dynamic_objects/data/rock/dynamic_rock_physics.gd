extends Node2D


static func collision_response(_parent: CharacterBody2D,
								dynamic_obj_profile: DynamicObjectProfile,
								collision: KinematicCollision2D,
								delta: float):
	var normal = collision.get_normal()
	_parent.velocity = _parent.velocity.slide(normal)
	var remainder = collision.get_remainder().slide(normal)
	_parent.move_and_collide(remainder)
	var tangent = normal.rotated(PI / 2)      # -- surface direction
	var forward_speed = _parent.velocity.dot(tangent) # -- _parent.velocity along the surface
	_parent.global_rotation += (forward_speed * delta) / dynamic_obj_profile.collision_shape.radius
