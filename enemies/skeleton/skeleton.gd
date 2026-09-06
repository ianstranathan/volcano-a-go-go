extends CharacterBody2D

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	DIE,
	REGENERATE
}

@export var can_regenerate: bool = false

@export_category("Movement")
@export var move_speed: float = 100.0
@export var patrol_distance: float = 500.0

@export_category("Awareness")

@export var require_line_of_sight: bool = true

@export_category("Combat")
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0

var state: State = State.IDLE

var player: Node2D = null

var patrol_origin: Vector2
var facing_direction: float = 1.0

var attack_timer: float = 0.0
var state_timer: float = 0.0

var is_dead: bool = false

@onready var player_detection_distance: float = $AwarenessArea/CollisionShape2D.shape.radius

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var awareness_area: Area2D = $AwarenessArea
@onready var attack_area: Area2D = $AttackHitbox

@onready var ledge_ray_rhs: RayCast2D = $LedgeRaysContainer/RHS
@onready var ledge_ray_lhs: RayCast2D = $LedgeRaysContainer/LHS

func _ready() -> void:
	patrol_origin = global_position
	change_state(State.PATROL)


func execute_tick(delta: float) -> void:
	if is_dead:
		return

	attack_timer -= delta
	state_timer -= delta

	update_player_awareness()

	match state:
		State.IDLE:
			state_idle(delta)

		State.PATROL:
			state_patrol(delta)

		State.CHASE:
			state_chase(delta)

		State.ATTACK:
			state_attack(delta)

		State.HURT:
			state_hurt(delta)

		State.DIE:
			state_die(delta)
	
	velocity.y += 980 * delta
	var motion = (velocity * delta) + Vector2(0., (0.5 * delta * delta * 980))
	global_position += motion
	
	var collision = move_and_collide(Vector2.ZERO)
	if collision:
		var normal = collision.get_normal()
		if normal.dot( Vector2.UP ) > 0:
			velocity.y = 0.
			
	var virtual = move_and_collide(Vector2(facing_direction, 0.) * 100 * delta, true)
	if virtual:
		#print(virtual.get_collider().name)
		set_facing_direction(-facing_direction)



func change_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state
	state_timer = 0.0

	match state:
		State.IDLE:
			sprite.speed_scale = 1.2
			sprite.play("idle")
			velocity.x = 0.0

		State.PATROL:
			sprite.speed_scale = 1.2
			sprite.play("walk")

		State.CHASE:
			sprite.speed_scale = 2.0
			sprite.play("walk")

		#State.ATTACK:
			#sprite.speed_scale = 1.2
			#sprite.play("attack")
			#velocity.x = 0.0

		State.HURT:
			sprite.speed_scale = 1.2
			sprite.play("hurt")
			velocity.x = 0.0

		State.DIE:
			sprite.speed_scale = 1.2
			sprite.play("die")
			velocity = Vector2.ZERO
			is_dead = true
		
		State.REGENERATE:
			sprite.speed_scale = 1.2
			sprite.play("regenerate")
			velocity = Vector2.ZERO
			#is_dead = true


func state_idle(_delta: float) -> void:
	velocity.x = 0.0

	if can_see_player():
		change_state(State.CHASE)
		return

	if state_timer <= 0.0:
		change_state(State.PATROL)


func check_wall_proximity():
	var r = $WallRaysContainer/RHS if facing_direction > 0 else $WallRaysContainer/LHS
	return r.is_colliding()


func state_patrol(_delta: float) -> void:
	if can_see_player():
		change_state(State.CHASE)
		return

	var distance_from_origin := global_position.x - patrol_origin.x

	velocity.x = facing_direction * move_speed
	#print(velocity.x)


#func is_at_wall(direction: float) -> bool:
	#if direction > 0:
		#return $WallRaysContainer/RHS.is_colliding()
	#elif direction < 0:
		#return $WallRaysContainer/LHS.is_colliding()
#
	#return false
	

func state_chase(_delta: float) -> void:
	if not is_instance_valid(player):
		player = null
		change_state(State.PATROL)
		return

	# We can no longer see the player.
	if not can_see_player():
		change_state(State.PATROL)
		return

	var distance_to_player := global_position.distance_to(
		player.global_position
	)

	# Close enough to attack.
	if distance_to_player <= attack_range:
		change_state(State.ATTACK)
		return

	var direction :float = sign(
		player.global_position.x - global_position.x
	)

	# Don't walk off a ledge while chasing.
	if direction != 0 and is_at_ledge(direction):
		velocity.x = 0.0
		return

	move_toward_player()


func move_toward_player() -> void:
	if not is_instance_valid(player):
		return

	var direction : float = sign(
		player.global_position.x - global_position.x
	)

	if direction != 0:
		velocity.x = direction * move_speed
		set_facing_direction(direction)
	else:
		velocity.x = 0.0


func state_attack(_delta: float) -> void:
	velocity = Vector2.ZERO

	# -- safety
	if not is_instance_valid(player):
		player = null
		change_state(State.PATROL)
		return

	# player goes out of range or out of sight
	if not can_see_player():
		change_state(State.PATROL)
		return

	var distance_to_player := global_position.distance_to(
		player.global_position
	)

	# Player moved away.
	if distance_to_player > attack_range:
		change_state(State.CHASE)
		return

	# Face player.
	var direction : float = sign(
		player.global_position.x - global_position.x
	)

	if direction != 0:
		set_facing_direction(direction)

	# Start attack.
	if attack_timer <= 0.0:
		$AnimationPlayer.play("attack_1")
		attack_timer = attack_cooldown



func state_hurt(_delta: float) -> void:
	velocity.x = 0.0

	if not sprite.is_playing():
		change_state(State.CHASE if can_see_player() else State.PATROL)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	print("Skeleton took damage: ", amount)

	# Example:
	#
	# health -= amount
	#
	# if health <= 0:
	#     change_state(State.DIE)
	# else:
	#     change_state(State.HURT)

	change_state(State.HURT)


# ============================================================
# DIE
# ============================================================

func state_die(_delta: float) -> void:
	velocity = Vector2.ZERO

	if not sprite.is_playing():
		queue_free()


func update_player_awareness() -> void:
	if is_instance_valid(player):
		var distance := global_position.distance_to(
			player.global_position
		)

		if distance > player_detection_distance:
			player = null

		return

	var bodies := awareness_area.get_overlapping_bodies()
	# - -get closest one
	var d = INF
	for body in bodies:
		if body is Player:
			var _d = global_position.distance_squared_to( body.global_position)
			if _d < d:
				d = _d
				player = body
			return
	#print( player )

func can_see_player() -> bool:
	if not is_instance_valid(player):
		return false

	var distance := global_position.distance_to(
		player.global_position
	)

	if distance > player_detection_distance:
		return false

	if not require_line_of_sight:
		return true

	return has_line_of_sight()


func has_line_of_sight() -> bool:
	if not is_instance_valid(player):
		return false

	var space_state := get_world_2d().direct_space_state

	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position
	)

	query.exclude = [self]

	# World + Player collision layers.
	query.collision_mask = 1 | 2

	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return true

	return result["collider"] == player


func set_facing_direction(d: float) -> void:
	facing_direction = sign(d)
	sprite.flip_h = facing_direction < 0



func has_ground_ahead(direction: float) -> bool:
	if direction > 0:
		return ledge_ray_rhs.is_colliding()
	elif direction < 0:
		return ledge_ray_lhs.is_colliding()

	return true


func is_at_ledge(direction: float) -> bool:
	return not has_ground_ahead(direction)
