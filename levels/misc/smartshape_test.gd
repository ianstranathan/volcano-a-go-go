@tool
extends Node2D

@export var my_shape: SS2D_Shape
@export var marker: Marker2D
@export var _apply := false:
	set(v):
		_apply = v
		if _apply and my_shape and marker:
			apply_polygon_sdf()
			_apply = false

func apply_polygon_sdf() -> void:
	var shape_resource = my_shape.shape_material
	if not shape_resource:
		print("No Shape Material assigned.")
		return
	
	var fill_mat = shape_resource.get("fill_mesh_material") as ShaderMaterial
	if not fill_mat:
		print("No valid ShaderMaterial on 'fill_mesh_material'.")
		return

	# 1. Access SmartShape2D's point-array sub-resource
	var point_array = my_shape.call("get_point_array")
	if not point_array:
		print("Could not retrieve SS2D_Point_Array sub-resource.")
		return

	# --- DYNAMIC API DISCOVERY ---
	print("--- INSPECTING SS2D_Point_Array METHODS ---")
	var methods = []
	for method_info in point_array.get_method_list():
		methods.append(method_info.name)
	print("Available methods: ", methods)
	
	var points: Array[Vector2] = []
	
	# Try Path A: Get keys via alternative names
	var key_method = ""
	for m in ["get_all_point_keys", "get_point_keys", "get_keys", "get_all_keys"]:
		if m in methods:
			key_method = m
			break
			
	if key_method != "":
		print("Attempting to fetch points using method: ", key_method)
		var keys = point_array.call(key_method)
		for key in keys:
			# Check how to get position
			if "get_point_position" in methods:
				points.append(point_array.call("get_point_position", key))
			elif "get_position" in methods:
				points.append(point_array.call("get_position", key))
	
	# Try Path B: If there's a direct point list/array fetch method
	elif "get_point_positions" in methods:
		points = point_array.call("get_point_positions")
	elif "get_vertices" in methods:
		points = point_array.call("get_vertices")
		
	# Try Path C: Let's inspect properties if methods failed
	if points.size() == 0:
		print("Method-based search failed. Checking internal properties...")
		for prop in point_array.get_property_list():
			if "points" in prop.name.to_lower():
				var val = point_array.get(prop.name)
				print("Found property '", prop.name, "' of type: ", typeof(val))
				if val is Array or val is Dictionary:
					# Attempt to extract positions
					for item in val:
						if item is Vector2:
							points.append(item)
						elif val is Dictionary and val[item] is Vector2:
							points.append(val[item])
						elif "position" in item:
							points.append(item.position)

	# --- END OF DISCOVERY ---

	var point_count = points.size()
	if point_count == 0:
		print("[ERROR] Could not extract points. Check the list of methods printed above!")
		return
	
	print("Successfully extracted ", point_count, " points!")

	# 3. Pad the array to match the shader's constant size (32)
	var shader_points: Array[Vector2] = []
	shader_points.resize(32)
	shader_points.fill(Vector2.ZERO)
	
	for i in range(min(point_count, 32)):
		shader_points[i] = points[i]
	
	# 4. Pass the data to the shader
	fill_mat.set_shader_parameter("polygon_points", shader_points)
	fill_mat.set_shader_parameter("point_count", point_count)
	
	var local_marker_pos = my_shape.to_local(marker.global_position)
	fill_mat.set_shader_parameter("marker_local_pos", local_marker_pos)
	
	print("Sent ", point_count, " vertices to Shader SDF.")
	
	# 5. Redraw
	my_shape.queue_redraw()
	if my_shape.has_method("force_update"):
		my_shape.call("force_update")

#@tool
#extends Node2D
#
#@export var my_shape: SS2D_Shape
#@export var marker: Marker2D
#@export var _apply := false:
	#set(v):
		#_apply = v
		#if _apply and my_shape and marker:
			#apply_marker_pos()
			#_apply = false # Reset the inspector button
#
#func apply_marker_pos() -> void:
	#var shape_resource = my_shape.shape_material
	#if not shape_resource:
		#print("No Shape Material resource assigned to the SmartShape2D.")
		#return
	#
	## Target the exact property we discovered: fill_mesh_material
	#var fill_mat = shape_resource.get("fill_mesh_material") as ShaderMaterial
	#
	#if fill_mat:
		#var local_pos: Vector2 = my_shape.to_local(marker.global_position)
		#
		## Set the parameter directly on the resource material
		#fill_mat.set_shader_parameter("marker_local_pos", local_pos)
		#print("Updated 'marker_local_pos' on resource to: ", local_pos)
		#
		## Force the shape to rebuild and draw with the new uniform value
		#my_shape.queue_redraw()
		#if my_shape.has_method("force_update"):
			#my_shape.call("force_update")
	#else:
		#print("Could not find a valid ShaderMaterial on 'fill_mesh_material'.")
