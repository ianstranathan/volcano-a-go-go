extends Node2D

var target_pos # -- needs to be nullable I guess
var rest_length: float = 0.0
var is_grappling: bool = false
var wrap_corner_pos: Vector2
var pivot_points_stack: Array[Vector2]

@export var ray_check_max_distance := 800
@export var swing_damping = 0.05 # -- how much it loses per frame

@export var item_interface: ItemInterface

@onready var ray_component = $RaycastItemComponent
@onready var rope := $Line2D

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
			var intersection_data = ray_component.get_intersection_data()
			if intersection_data:
				initialize_grapple( intersection_data[0], intersection_data[1] )
				rope.show()
				# -- send to everyone but yourself and the host
				set_target_on_interpolated.rpc( target_pos )
				$MovementOverrideComponent.start()
		else:
			on_item_stopped()
	
	if target_pos:
		handle_grapple(delta)


func on_item_stopped():
	is_grappling = false
	pivot_points_stack.clear()
	#print("grapple hook finished")
	target_pos = null
	shape_node = null
	rope.hide()
	set_target_on_interpolated.rpc()
	$MovementOverrideComponent.finish()


# -- client who has authority over this player calls this to everyone
#@rpc("authority", "call_local", "reliable")
#func _sync_destruction():
	#call_deferred("queue_free")


# -- visuals can be decoupled from the deterministic tick
# Assume pivot_points_stack starts with [initial_anchor_point]
func _physics_process(_delta: float) -> void:
	if is_grappling:
		# We need: Player Position (index 0) + All Pivots
		var required_points = pivot_points_stack.size() + 1
		
		if rope.points.size() != required_points:
			rope.clear_points()
			rope.add_point(Vector2.ZERO) # Player is always at local zero
			for p in pivot_points_stack:
				rope.add_point(to_local(p))
		else:
			rope.set_point_position(0, Vector2.ZERO)
			# Fill from the end of the stack (most recent pivot is index 1)
			# Anchor point is the last index.
			for i in range(pivot_points_stack.size()):
				var point_index = pivot_points_stack.size() - i
				rope.set_point_position(point_index, to_local(pivot_points_stack[i]))


var previous_angle: float = 0.0
func should_wrap_around_corner() -> bool:
	var from_coll_point_2_corner = target_pos - wrap_corner_pos
	var from_coll_point_2_player = target_pos - player_ref.global_position
	
	var current_angle = from_coll_point_2_player.angle_to(from_coll_point_2_corner)
	var wrapped = false
	# -- wrap happens when this angle flips
	if previous_angle != 0 and sign(current_angle) != sign(previous_angle):
		wrapped = true
	previous_angle = current_angle
	return wrapped


var shape_node: CollisionShape2D
func get_closest_corner() -> Vector2:
	var rect_shape = shape_node.shape as RectangleShape2D
	if rect_shape == null or target_pos == null:
		return Vector2.ZERO

	var local_point = shape_node.to_local(target_pos)
	var extents = rect_shape.size * 0.5

	var corners = [
		Vector2(-extents.x, -extents.y),
		Vector2( extents.x, -extents.y),
		Vector2( extents.x,  extents.y),
		Vector2(-extents.x,  extents.y)
	]

	var closest_corner = null
	var min_dist = INF

	for corner in corners:
		# Only consider corners LOWER than the point
		if corner.y < local_point.y:
			continue

		var dist = local_point.distance_squared_to(corner)
		if dist < min_dist:
			min_dist = dist
			closest_corner = corner

	# Fallback: if none were below, just use normal closest
	if closest_corner == null:
		for corner in corners:
			var dist = local_point.distance_squared_to(corner)
			if dist < min_dist:
				min_dist = dist
				closest_corner = corner

	return shape_node.to_global(closest_corner)


var  original_intersection_pos: Vector2
func initialize_grapple( intersection_pos: Vector2, collider: CollisionObject2D):
	shape_node = collider.get_node("CollisionShape2D") # TODO
	is_grappling = true
	update_pivot( intersection_pos )


#func update_pivot(new_pivot_point: Vector2):
	#pivot_points_stack.append(new_pivot_point)
	#target_pos = new_pivot_point
	#rest_length = (target_pos - player_ref.global_position).length()
	#wrap_corner_pos = get_closest_corner()
var wrap_directions_stack: Array[float] # Stores 1 or -1
var wrap_angles_stack: Array[float]
func update_pivot(new_pivot_point: Vector2):
	if pivot_points_stack.size() > 0:
		var angle_to_player = (player_ref.global_position - new_pivot_point).angle()
		wrap_angles_stack.append(angle_to_player)
		
		# Determine if we wrapped coming from the left or right
		var side = sign(previous_angle) 
		wrap_directions_stack.append(side)

	pivot_points_stack.append(new_pivot_point)
	target_pos = new_pivot_point
	rest_length = (target_pos - player_ref.global_position).length()
	wrap_corner_pos = get_closest_corner()


func unwrap_pivot():
	pivot_points_stack.pop_back()
	wrap_angles_stack.pop_back()
	wrap_directions_stack.pop_back()
	
	target_pos = pivot_points_stack.back()
	# Recalculate rest_length based on remaining rope
	# Total rope length should be preserved, minus the distance to the old pivot
	rest_length = (target_pos - player_ref.global_position).length() 
	wrap_corner_pos = get_closest_corner()


func check_unwrap_condition(current_diff: float) -> bool:
	var entry_side = wrap_directions_stack.back()
	# If we entered from the positive side and now diff is negative (or vice versa)
	return sign(current_diff) != entry_side


func handle_grapple(delta):
	var to_anchor = target_pos - player_ref.global_position
	var current_dist = to_anchor.length()
	var target_dir = to_anchor.normalized()

	if should_wrap_around_corner():
		update_pivot(wrap_corner_pos)
	
	if pivot_points_stack.size() > 1:
		var current_angle_to_player = (player_ref.global_position - target_pos).angle()
		var wrap_angle = wrap_angles_stack.back()
		
		# We check if the player has swung back past the entry angle.
		# Note: angle_difference handles the -PI to PI wrap-around math automatically.
		var diff = angle_difference(current_angle_to_player, wrap_angle)
		
		# If the sign of the difference changes compared to the movement 
		# that caused the wrap, we unwrap. 
		# A simpler check: if the player crosses the threshold.
		if abs(diff) > 0.5: # Small threshold to prevent flickering
			# You need to track which direction the wrap happened (CW or CCW)
			# to know if the diff sign means "going further" or "going back".
			# For simplicity, here is the pop logic:
			if check_unwrap_condition(diff): 
				unwrap_pivot()
				
	if current_dist > rest_length:
		player_ref.global_position = target_pos - (target_dir * rest_length)
		
		# B. Vector Projection: Keep only the sideways (tangent) velocity
		# This is the "Spiderman" feel: gravity pulls you down, 
		# the rope pulls you in, and you accelerate into the curve.
		var radial_velocity = player_ref.velocity.dot(target_dir)
		
		if radial_velocity < 0: # If moving away from the anchor
			# Remove only the velocity component that pulls against the rope
			player_ref.velocity -= target_dir * radial_velocity
			
			# Air Resistance / Friction
			# lose a tiny bit of energy to friction
			player_ref.velocity *= (1.0 - (0.05 * delta))


func set_player_ref(p: Player) -> void:
	player_ref = p
	
	
#func _draw():
	#if is_grappling:
		##var active_pivot = pivot_points_stack.back()
		##draw_line(to_local(active_pivot), to_local(wrap_corner_pos), Color.CYAN, 10.0)
		#draw_circle(to_local(wrap_corner_pos), 20.0, Color.ORANGE)
		##draw_line(to_local(active_pivot), to_local(player_ref.global_position), Color.WHITE, 1.0)


#func _process(_delta):
	#queue_redraw() # Forces _draw() to update every frame
