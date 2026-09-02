extends RefCounted

class_name MyPhysicsUtils

static func resolve_collision(A: Player, 
							  B: Player,
							  kinematic_collision: KinematicCollision2D) -> void:
	var contact_normal = kinematic_collision.get_normal()
	var relative_velocity = A.velocity - B.velocity
	var velocity_along_normal = relative_velocity.dot(contact_normal)
	
	if velocity_along_normal > 0:
		return

	var e := 0.5
	var inv_mass_sum = A.kd.inv_mass + B.kd.inv_mass
	if inv_mass_sum <= 0: 
		return
	
	var j = -(1 + e) * velocity_along_normal
	j /= inv_mass_sum
	
	var impulse = j * contact_normal
	
	A.velocity += A.kd.inv_mass * impulse
	B.velocity -= B.kd.inv_mass * impulse
