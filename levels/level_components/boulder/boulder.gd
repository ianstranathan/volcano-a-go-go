extends CharacterBody2D

var g: float = 980.0
@export var radius: float = 50

func _physics_process(delta: float) -> void:
	velocity.y += get_g() * delta
	var motion = velocity * delta
	var collision = move_and_collide(motion)

	if collision:
		var normal = collision.get_normal()
		velocity = velocity.slide(normal)
		var remainder = collision.get_remainder().slide(normal)
		move_and_collide(remainder)
		var tangent = normal.rotated(PI / 2)      # -- surface direction
		var forward_speed = velocity.dot(tangent) # -- velocity along the surface
		global_rotation += (forward_speed * delta) / radius
	else:
		pass

func get_g() -> float:
	return g
