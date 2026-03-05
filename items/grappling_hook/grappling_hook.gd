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
	item_interface.tick_update_fn = tick_update
	item_interface.stopped.connect(on_item_stopped)
	item_interface.destroyed.connect( func():
		call_deferred("queue_free"))
	
	ray_component.initialize_ray( grapple_max_distance )
	

# -- NOTE
# -- this needs to be replaced with something that scales better
# -- and integrates into deterministic tick
#@rpc("authority", "call_remote", "reliable")
#func show_rope_on_remote(pos: Vector2):
	#rope.show()
	#rope.set_point_position(1, pos)
#
#
#@rpc("authority", "call_remote", "reliable")
#func hide_rope_on_remote():
	#rope.hide()


func tick_update(delta: float, cmd: PlayerCommand):
	ray_component.tick_update(cmd)
	
	if cmd.item_use_pressed and !target:
		var hit_pos = ray_component.get_intersection_pos()
		if hit_pos:
			# -- both host and client have to do this on the same tick
			target = hit_pos 
			rope.show()
			#show_rope_on_remote.rpc(to_local(target))
			$MovementOverrideComponent.start()
	
	if target:
		handle_grapple(delta)


func on_item_stopped():
	target = null
	rope.hide()
	#hide_rope_on_remote.rpc()
	$MovementOverrideComponent.finish()


# -- client who has authority over this player calls this to everyone
@rpc("authority", "call_local", "reliable")
func _sync_destruction():
	queue_free()


# -- visuals can be decoupled from the deterministic tick
func _physics_process(_delta: float) -> void:
	if target:
		rope.set_point_position(1, to_local(target))
		rope.set_point_position(0, Vector2.ZERO)


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
	#rope.set_point_position(1, to_local(target))
