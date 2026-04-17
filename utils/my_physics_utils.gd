extends RefCounted

class_name MyPhysicsUtils

static func resolve_collision(A: Player, B: Player, kinematic_collision: KinematicCollision2D):
	var contact_normal = kinematic_collision.get_normal()
	var relative_velocity = A.velocity - B.velocity
	var velocity_along_normal = relative_velocity.dot(contact_normal)
	
	if velocity_along_normal > 0:
		return

	var e := 0.5
	var inv_mass_sum = A.inv_mass + B.inv_mass
	if inv_mass_sum == 0: return 
	
	var j = -(1 + e) * velocity_along_normal
	j /= inv_mass_sum
	
	var impulse = j * contact_normal
	A.velocity += A.inv_mass * impulse
	B.velocity -= B.inv_mass * impulse

	
	#var depth = kinematic_collision.get_depth()
	#var percent = 0.4 # How much of the overlap to fix per frame
	#var slop = 0.01   # Allowed overlap
	#var correction = max(depth - slop, 0.0) / inv_mass_sum * percent * contact_normal
	#
	#A.global_position += A.inv_mass * correction
	#B.global_position -= B.inv_mass * correction
	

	
#static func resolve_collision(A: Player, B: Player, kinematic_collision: KinematicCollision2D):
	#var contact_normal = kinematic_collision.get_normal()
	## -- relative velocity
	#var relative_velocity = A.velocity - B.velocity
	## vec3.subtract(relativeVelocity, A.vel, B.vel);
	#
	## -- Do not resolve if velocities are separating
	#if relative_velocity.dot(contact_normal) > 0:
		#return
	## -- Take least elastic restitutionCoeff coefficient
	## -- let e = Math.min( A.restitutionCoeff, B.restitutionCoeff);
	#
	#var e := 0.8
	## -- Calculate part of the impulse in the direction of the contact normal
	## -(1 + e) * relativeVelocity / (A.inv_mass - B.inv_mass)
	## vec3.scale(relativeVelocity, relativeVelocity, -(1 + e) / (A.inv_mass + B.inv_mass));
	#relative_velocity = relative_velocity * -(1 + e) * relative_velocity / (A.inv_mass + B.inv_mass)
	##let impulse = vec3.create();
	##let frictionImpulse = vec3.create();
#
	## -- Penetration normal
	#var the_mtv = kinematic_collision.get_depth() * contact_normal
	## -- Penetration Tangential
	#var tangentialDir = Vector2(the_mtv.y, -the_mtv.x) # -- for friction:
#
	## -- Impulse components in normal and tangential directions
	#var impulseMagnitudeInContactNormal = relative_velocity.dot( the_mtv )
	#var impulseMagnitudeInContactTangential = relative_velocity.dot( tangentialDir)
#
	#var impulse : Vector2 = the_mtv * impulseMagnitudeInContactNormal
	#
	## -- Apply impulse to bodies' velocities:
	#var tmp = impulse  * (1.0 / A.mass)
	#A.velocity += tmp
	#
	#tmp = impulse * (1.0 / B.mass)
	#B.velocity -= tmp
	#
	#var mu = 0.43;
	#
	#var frictionImpulse =  tangentialDir * -mu * impulseMagnitudeInContactTangential
	#
	#tmp = frictionImpulse * ( 1.0 / A.mass)
	#A.velocity -= tmp 
	#
	#tmp = frictionImpulse * (1.0 / B.mass)
	#B.velocity += tmp
