#extends Item
extends Node2D

"""
Multiplayer authority is decided by item manager at spawn
"""

@export var item_interface: ItemInterface
@export var swing_power: float = 100 # -- coefficient for swinging manually
@export var reel_in_speed: float = 50
@export var grapple_change_rate := 200.0
@export var swing_damping := 1.0
@export var grapple_max_distance: float = 800
@export var grapple_min_distance: float = 50

@onready var rest_length = grapple_min_distance
@onready var ray_component = $RaycastItemComponent
@onready var rope := $Line2D


var target
var input_manager: LocalPlayerController
var player_ref: Player


func _ready() -> void:
	#----------------------------------- item interface / dependency injection
	item_interface.can_use_fn = func(): return true # you can always use this
	item_interface.used.connect(on_used)
	item_interface.stopped.connect( func():
		if is_multiplayer_authority():
			sync_grapple_state.rpc(false, Vector2.ZERO))

	item_interface.destroyed.connect( func():
		call_deferred("queue_free"))

	# -- is multiplayer authority is injected by input manager
	# -- pickup -> item_manager -> instanitates this, assigns it stuff
	if is_multiplayer_authority():
		assert(input_manager and item_interface)
		#--------------------------------------- Raycast interface
		$RaycastItemComponent.initialize_ray(grapple_max_distance,
											 func(the_ray: RayCast2D):
												the_ray.look_at(input_manager.aiming_pos()))
	else:
		# -- save some cpu cycles
		$RaycastItemComponent.set_process(false)


func on_used():
	if is_multiplayer_authority():
		if target:
			# Tell everyone to stop
			sync_grapple_state.rpc(false, Vector2.ZERO) 
		else:
			var hit_pos = ray_component.get_intersection_pos()
			if hit_pos:
				sync_grapple_state.rpc(true, hit_pos)


@rpc("authority", "call_local", "reliable")
func sync_grapple_state(active: bool, pos: Vector2):
	if active:
		target = pos
		rope.show()
		$MovementOverrideComponent.start()
	else:
		target = null
		rope.hide()
		$MovementOverrideComponent.finish()


# -- client who has authorit over this player calls this to everyone
@rpc("authority", "call_local", "reliable")
func _sync_destruction():
	queue_free()


func _physics_process(delta: float) -> void:
	if target:
		handle_grapple(delta)
		if is_multiplayer_authority():
			# -- inverting these to match intuion
			var move_input: float = input_manager.movement_vector().y
			rest_length += delta * move_input * grapple_change_rate
			rest_length = clamp(rest_length, grapple_min_distance, grapple_max_distance)


func handle_grapple(delta):
	var to_anchor = target - player_ref.global_position
	var current_dist = to_anchor.length()
	var target_dir = to_anchor.normalized()
	
	rest_length = max(rest_length - reel_in_speed * delta, 20.0)
	if current_dist > rest_length:
		var outward_vel = player_ref.velocity.dot(target_dir)
		if outward_vel < 0:
			player_ref.velocity -= target_dir * outward_vel
		var overshoot = current_dist - rest_length
		var responsiveness = 0.25
		player_ref.velocity += target_dir * (overshoot * responsiveness)
		
		# -- make player velocity tangent to swing
		player_ref.velocity = player_ref.velocity.project(player_ref.velocity.normalized())
		
	player_ref.velocity *= (1.0 - (swing_damping * delta)) # -- Damping / Friction
	rope.set_point_position(1, to_local(target))
