extends CharacterBody2D
class_name DynamicObject

# --TODO
# -- a dynamic object knowing how a player is structured is def
# -- anti-pattern / backwards
# -- but I can't think of how else to account for the case where there
# -- is a small off-by-one area overlap miss and the item isn't grabbed

signal put_to_sleep( _self: DynamicObject)
signal woke_up(_self: DynamicObject)
signal got_grabbed( id: int )

# -- this is set from the manager loading / instancing it.
var dynamic_object_profile: DynamicObjectProfile: 
	set( v ):
		dynamic_object_profile = v

		# -- visual
		add_child( v.visual_scene.instantiate() )
		# -- update collision shape
		assert(v.collision_shape)
		$CollisionShape2D.shape = v.collision_shape
		
		# -- updat area collision shape
		if v.grab_area_collision_shape:
			$Area2D/CollisionShape2D.shape = v.grab_area_collision_shape
		else:
			# -- fallback to physics shape
			$Area2D/CollisionShape2D.shape = v.collision_shape
			print("Yo, you forgot an grabbing area in rsc: ", v)


var spawn_id = -1
var grabbing_player_area: Area2D

enum DynamicObjectState{
	SLEEPING,
	ACTIVE,
	GRABBED
}
var state: DynamicObjectState = DynamicObjectState.ACTIVE
var sleep_threshold = 20  # -- num ticks to go to sleep
var sleep_threshold_t = 0
@onready var last_pos = global_position

#  -- probably event throw this guy on the physics component
var TERMINAL_FALL_SPEED: float = 1400.0

func _ready() -> void:
	assert( dynamic_object_profile )
	assert( dynamic_object_profile.physics_script )
	$Area2D.area_entered.connect( on_player_grab_area_entered )


func execute_tick( delta: float) -> void:
	last_pos = global_position
	match state:
		DynamicObjectState.ACTIVE:
			
			if velocity.y <= TERMINAL_FALL_SPEED:
				velocity.y += get_g() * delta
				
			global_position += (velocity * delta) + Vector2(0., (0.5 * delta * delta * get_g()))
			
			var collision = move_and_collide(Vector2.ZERO)
			
			# -- all objects should be able to do whatever / bespoke motion
			if collision:
				dynamic_object_profile.physics_script.collision_response( self, dynamic_object_profile,collision, delta )
			
			# -- we need all dynamic objects to be querying their sleep / active state
			if last_pos.is_equal_approx(global_position):
				sleep_threshold_t += delta
				if sleep_threshold_t >= sleep_threshold:
					set_state(DynamicObjectState.SLEEPING)
					return
			else:
				sleep_threshold_t = 0.0
				return

		DynamicObjectState.GRABBED:
			global_position = grabbing_player_area.global_position
			return


func set_state(new_state: DynamicObjectState) -> void:
	if state == new_state:
		return
	state = new_state
	match state:
		DynamicObjectState.SLEEPING:
			put_to_sleep.emit( self )
		DynamicObjectState.ACTIVE:
			woke_up.emit( self)
		DynamicObjectState.GRABBED:
			if state == DynamicObjectState.SLEEPING:
				woke_up.emit( self)


func get_g() -> float:
	return 980


func on_player_grab_area_entered( area: Area2D) -> void:
	"""
	maybe do some visuals, highlight the item or something to
	indicate it can be grabbed
	"""
	pass


func can_be_grabbed():
	return (grabbing_player_area == null)


func get_grabbed( grbbing_area: Area2D, calling_id=null):
	$CollisionShape2D.set_deferred("disabled", true)
	$Area2D.set_deferred("monitorable", false)
	$Area2D.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	grabbing_player_area = grbbing_area
	set_state( DynamicObjectState.GRABBED )
	#if calling_id:
		#got_grabbed.emit( calling_id )
	if calling_id:
		remote_get_grabbed.rpc(calling_id)


@rpc("any_peer", "reliable", "call_remote")
func remote_get_grabbed( id: int):
	# -- so, the host is simulating the remote already
	# -- just like in items, we shouldnt' need to manually tell
	# -- the corresponding remote player to pick up the object
	if !multiplayer.is_server():
		# -- get player ref on this machine
		# -- force it to take this object as a reference
		NetManager.player_instances_by_player_id.get(id).grab_dynamic_object( self )

# -- TODO
# -- My mental model is from the POV of the calling player
# -- but maybe this should be from host POV since host is running the same commands
func get_thrown(throw_vel: Vector2, calling_id=null):
	$CollisionShape2D.set_deferred("disabled", false)
	$Area2D.set_deferred("monitorable", true)
	$Area2D.set_deferred("monitoring", true)
	set_state( DynamicObjectState.ACTIVE )
	
	# -- collision test to get outside of player?
	velocity = throw_vel
	#if calling_id:
		#got_grabbed.emit( thow_vel, calling_id )
	#if calling_id:
		#remote_got_thrown.rpc( calling_id )


#@rpc("any_peer", "reliable", "call_remote")
#func remote_got_thrown( id: int):
	## -- so, the host is simulating the remote already
	## -- just like in items, we shouldnt' need to manually tell
	## -- the corresponding remote player to pick up the object
	#if !multiplayer.is_server() or id == get_multiplayer_authority():
		## -- get player ref on this machine
		## -- force it to take this object as a reference
		#var player = NetManager.player_instances_by_player_id.get(id)
		#add_collision_exception_with(player)
		## - -throw
		#player.grab_dynamic_object()
		#
		#await get_tree().create_timer(0.2).timeout
		#remove_collision_exception_with(player)

func toss( _v ):
	#emit_signal( "got_tossed", Vector2(v * throw_dir_coeff(), 0.0))
	grabbing_player_area = null
	set_state( DynamicObjectState.ACTIVE )
