extends Node2D

"""
Multiplayer authority is decided by item manager at spawn
"""

@export var item_interface: ItemInterface
@export var swing_power: float = 100 # -- coefficient for swinging manually
@export var reel_in_speed: float = 50
@export var grapple_change_rate := 200.0
@export var swing_damping := 1.0
@export var ray_check_max_distance: float = 800
@onready var ray_component = $RaycastItemComponent
@onready var rope := $Line2D


var target_pos
var player_ref: Player


func _ready() -> void:
	#----------------------------------- item interface / dependency injection
	item_interface.tick_update_fn = tick_update
	item_interface.stopped.connect(on_item_stopped)
	item_interface.destroyed.connect( func():
		call_deferred("queue_free"))
	
	if is_multiplayer_authority() or multiplayer.is_server():
		ray_component.initialize_ray( ray_check_max_distance )
	

# -- NOTE
# -- this needs to be replaced with something that scales better
# -- and integrates into deterministic tick
@rpc("any_peer", "reliable")
func set_target_on_interpolated(pos=null):
	if !multiplayer.is_server():
		target_pos = pos
		if pos:
			rope.show()
		else:
			rope.hide()


func tick_update(delta: float, cmd: PlayerCommand):
	ray_component.tick_update(cmd)
	
	if cmd.item_use_pressed:
		if !target_pos:
			var hit_pos = ray_component.get_intersection_pos()
			if hit_pos:
				# -- both host and client have to do this on the same tick
				target_pos = hit_pos 
				rope.show()
				# -- send to everyone but yourself and the host
				set_target_on_interpolated.rpc( target_pos )
				$MovementOverrideComponent.start()
				if is_multiplayer_authority() and not player_ref.is_replaying:
					Events.emit_signal("play_world_sound",
										AudioDb.WorldSoundId.HOOKSHOT_FIRE,
										global_position,0,1,
										{})
		else:
			on_item_stopped()
	
	if target_pos:
		handle_hookshot()


func on_item_stopped():
	#print("grapple hook finished")
	target_pos = null
	rope.hide()
	set_target_on_interpolated.rpc()
	$MovementOverrideComponent.finish()


# -- client who has authority over this player calls this to everyone
#@rpc("authority", "call_local", "reliable")
#func _sync_destruction():
	#call_deferred("queue_free")


# -- visuals can be decoupled from the deterministic tick
func _physics_process(_delta: float) -> void:
	if target_pos:
		rope.set_point_position(1, to_local(target_pos))


func handle_hookshot():
	var to_anchor = target_pos - player_ref.global_position
	var distance = to_anchor.length()
	var target_dir = to_anchor.normalized()
	
	# 1. Constant Pull Speed
	var pull_speed = 1500.0 
	player_ref.velocity = target_dir * pull_speed
	
	# 2. Arrival Logic (Stop when close enough)
	if distance < 50.0:
		# Stop pulling and perhaps give a little "hop" at the end
		#state = NORMAL # Switch back to your movement state
		player_ref.velocity = player_ref.velocity * 0.5
		on_item_stopped()



func set_player_ref(p: Player) -> void:
	player_ref = p
