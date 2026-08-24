extends CharacterBody2D
class_name DynamicObject

@onready var sprite: Sprite2D = $Sprite2D
var dynamic_object_type: DynamicObjectsDb.DynamicObjectType
var spawn_id = -1

enum State{
	CARRIED,
	FREE
}
var is_on_ground = true
var state : State = State.FREE
var radius: float
var rotational_vel = 10.0

func _ready() -> void:
	if sprite.texture == null:
		return
	sprite.texture = DynamicObjectsDb.ROCK_ATLAS
	sprite.region_enabled = true
	sprite.region_rect = DynamicObjectsDb.ROCK_ATLAS_REGIONS[dynamic_object_type]
	radius = min(sprite.region_rect.size.x,sprite.region_rect.size.y) * 0.3
	$CollisionShape2D.shape.radius = radius
	$Area2D/CollisionShape2D.shape.radius = radius


func execute_tick( delta: float) -> void:
	if state == State.FREE:
		if is_on_ground:
			global_position += (velocity * delta) + Vector2(0., (0.5 * delta * delta * get_g()))
			velocity.y += get_g() * delta
			var collision = move_and_collide(Vector2.ZERO)
			
			if collision:
				var normal = collision.get_normal()
				if normal.dot(Vector2.UP) > 0.7:
					velocity.y = 0.
					is_on_ground = true
			else:
				is_on_ground = false
		else:
			# -- roll with no slip if rock
			# -- need to amtch dynamic_object_type
			# -- just testing for now
			velocity.x = radius * rotational_vel
			rotation += rotational_vel * delta

func get_g() -> float:
	return 980
