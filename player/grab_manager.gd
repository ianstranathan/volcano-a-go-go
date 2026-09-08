extends Area2D

@export var player_ref: Player
@export var throw_speed: float = 200

# -- so I don't forget to set it in the player for the intermediary state stuff
signal grabbed_a_dynamic_object( d: DynamicObject )
signal threw_a_dynamic_object()

var dynamic_objects_manager_ref

var grabbed_dynamic_object_ref = null:
	set(v):
		grabbed_dynamic_object_ref = v
		if v:
			grabbed_a_dynamic_object.emit( v )
		else:
			threw_a_dynamic_object.emit()
 
@onready var player: Player = get_parent()

func _ready() -> void:
	$CollisionShape2D.debug_color = Color(0, 0.6, 0.7, 0.42)
	#print("grab_manager: ", get_multiplayer_authority())


# -- this is a local only thing
# -- mental model is like this:
# -- local player grabs -> this changes the player's is_holding_something
# -- player state automatically looks this when it's being set
# -- when the remote state is being updated, this state id is passed and looked up
# -- in the dynamic world manager
# -- then grabbed locally with the object override
@rpc("call_remote", "any_peer", "reliable")
func grab_rpc_everyone_else( peer_id: int, object_spawn_id: int):
	# -- call_remote & only called from server, so host can't call it anyway
	if multiplayer.get_unique_id() != peer_id:
		grab_dynamic_object( dynamic_objects_manager_ref.get_object( object_spawn_id ) )


@rpc("authority", "reliable")
func make_authority_drop_it():
	throw_dynamic_object( Vector2.ZERO )


func grab_dynamic_object(object_override=null) -> void:
	var success = false
	# -- grab
	if !grabbed_dynamic_object_ref:
		# -- remote versions of local client need to grab same object
		if object_override:
			grabbed_dynamic_object_ref = object_override
			grabbed_dynamic_object_ref.get_grabbed( self )
		# -- this is how local player picks up a dynamic object
		else:
			var areas_that_can_be_grabbed = get_overlapping_areas().filter( func(grabbable_area):
					return can_grab( grabbable_area ))
			#print(areas_that_can_be_grabbed)
			var closest_area  = get_closest_grabbable( areas_that_can_be_grabbed )
			#print(closest_area)
			if closest_area:
				# -- not great, but we're mandating that this area only lives on this physics
				# -- layer associated with dynamic areas
				grabbed_dynamic_object_ref = closest_area.get_parent()
				assert(grabbed_dynamic_object_ref)
				grabbed_dynamic_object_ref.get_grabbed( self )
		success = (grabbed_dynamic_object_ref != null)
	if success:
		if multiplayer.is_server():
			grab_rpc_everyone_else.rpc( int(player_ref.name),
										grabbed_dynamic_object_ref.spawn_id )
		#else:
			#make_authority_drop_it.rpc_id(int(player_ref.name))
			# -- tell the grabbing player to drop iot
			
const sqrt_two_over_two = -1.41 / 2.;


@rpc("call_remote", "any_peer", "reliable")
func throw_rpc_everyone_else( peer_id: int ):
	# -- call_remote & only called from server, so host can't call it anyway
	if multiplayer.get_unique_id() != peer_id:
		throw_dynamic_object( )


func throw_dynamic_object(velocity_override=null):
	#print("--- calling on Peer ID: ", multiplayer.get_unique_id(), " ---")
	#print("object spawn id: ", grabbed_dynamic_object_ref.spawn_id)
	# -- projectile / thrown object should be 
	# -- RTT / 2. ahead, so you need to account for this
	assert(grabbed_dynamic_object_ref != null)
	# -- this can be a functional arg, might be cool to allow player
	# -- to have an upgrade or something (or a style like in downwell)
	# -- that allows throwing up or straight down or something
	var throw_dir = Vector2(sign(player.last_non_zero_move_input.x), -sqrt_two_over_two).normalized()
	var throw_vel = velocity_override if velocity_override else throw_dir * player.throw_speed
	#print("throwing: ", get_multiplayer_authority())
	#print("throwing is server: ", multiplayer.is_server())
	grabbed_dynamic_object_ref.global_position += throw_dir * 20.0
	grabbed_dynamic_object_ref.get_thrown( throw_vel )
	grabbed_dynamic_object_ref = null
	
	if multiplayer.is_server():
		throw_rpc_everyone_else.rpc( int(player_ref.name) )



func can_grab( grabbable_area : Area2D) -> bool:
	# -- are we facing the way? / is the item in front of us
	var r = grabbable_area.global_position - global_position
	var facing_dir = player_ref.last_non_zero_move_input.x
	return (facing_dir * r.x >= 0)


func _process(_delta: float) -> void:
	if get_tree().debug_collisions_hint:
		if has_overlapping_areas():
			$CollisionShape2D.debug_color = Color(1, 0, 1, 0.4) 
		else:
			$CollisionShape2D.debug_color = Color(0, 0.6, 0.7, 0.42)


func get_closest_grabbable( grabbable_areas: Array):
	if grabbable_areas.is_empty():
		return
	
	return grabbable_areas.reduce(func(a, b):
		return a if a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position) else b
	)


func set_player_weight_modifier():
	pass
