extends Camera2D

var target: CharacterBody2D 
var horizontal_look_ahead_distance: float
var vertical_look_ahead_distance: float

@export_group("Smoothing")
@export var lead_speed: float = 5.0    
@export var follow_speed: float = 10.0
var target_offset: Vector2 = Vector2.ZERO

@export_group("Camera Shake")
@export var noise_texture: NoiseTexture2D  
@export var decay: float = 0.8  # Trauma loss per second
@export var max_offset: float = 40
@export var max_roll: float = 0.1  

var noise: FastNoiseLite  
var trauma: float = 0.0  
var trauma_power: int = 2  
var noise_y: int = 0
var last_direction: float = 1.0

enum ShakeType { GENERAL, DIRECTIONAL }
var shake_type: ShakeType = ShakeType.GENERAL


var current_ease_func: Callable
var active_shakes: Array[ShakeInstance] = []

func _ready() -> void:
	Events.shake_cam.connect(on_shake_cam)

	if noise_texture and noise_texture.noise is FastNoiseLite:
		noise = noise_texture.noise
	else:
		noise = FastNoiseLite.new()
		noise.seed = randi()
		noise.frequency = 0.5
	
	viewport_size_change_callback()
	get_viewport().size_changed.connect(viewport_size_change_callback)


func _physics_process(delta: float) -> void:
	if not target:
		return
		
	var desired_offset_x = get_persistent_direction() * horizontal_look_ahead_distance
	var desired_offset_y = sign(target.velocity.y) * vertical_look_ahead_distance if not is_zero_approx(target.velocity.y) else 0.0
	
	target_offset.x = lerp(target_offset.x, desired_offset_x, lead_speed * delta)
	target_offset.y = lerp(target_offset.y, desired_offset_y, lead_speed * delta)
	
	var desired_position = target.global_position + target_offset
	global_position = global_position.lerp(desired_position, follow_speed * delta)


func _process(delta: float) -> void:
	if active_shakes.is_empty():
		rotation = 0
		offset = Vector2.ZERO
		return

	var general_trauma: float = 0.0
	var directional_displacement: Vector2 = Vector2.ZERO
	
	var i = active_shakes.size() - 1
	while i >= 0:
		var shake = active_shakes[i]
		var current_intensity = shake.update(delta)
		
		if shake.direction == Vector2.ZERO:
			# General shake accumulates standard omni-directional trauma
			general_trauma += current_intensity
		else:
			# Directional shake moves the camera precisely along its axis
			# Multiplying by noise allows it to jitter *along* that line rather than being a static push
			noise_y += 1
			var axis_jitter = noise.get_noise_2d(noise.seed, noise_y)
			directional_displacement += shake.direction * (max_offset * current_intensity * axis_jitter)
		
		if shake.is_finished():
			active_shakes.remove_at(i)
		i -= 1
	
	# Clamp general trauma to cap our rotational chaos
	general_trauma = clamp(general_trauma, 0.0, 1.0)
	
	_apply_combined_shake(general_trauma, directional_displacement)


func _apply_combined_shake(general_trauma: float, directional_displacement: Vector2) -> void:
	noise_y += 1
	var current_seed = noise.seed
	
	# -- Calculate rotational and basic noise offsets from general trauma
	rotation = max_roll * general_trauma * noise.get_noise_2d(current_seed, noise_y)
	
	var general_offset = Vector2(
		max_offset * general_trauma * noise.get_noise_2d(current_seed + 123, noise_y),
		max_offset * general_trauma * noise.get_noise_2d(current_seed + 456, noise_y)
	)
	
	# -- Combine the random general offset with calculated directional displacement
	offset = general_offset + directional_displacement


func on_shake_cam(shake: ShakeInstance):
	active_shakes.append(shake)


func default_ease(t: float) -> float:
	return pow(t, trauma_power)


func inverted_parabola(t: float) -> float:
	var clamped_t = clamp(t, 0.0, 1.0)
	return -(3.0 * clamped_t - 1.0) * (3.0 * clamped_t - 1.0) + 1.0


func get_persistent_direction() -> float:
	var current_velocity = target.velocity.x
	if not is_zero_approx(current_velocity):
		last_direction = sign(current_velocity)
	return last_direction


func viewport_size_change_callback() -> void:
	var vp = get_viewport()
	if vp:
		horizontal_look_ahead_distance = vp.size.x / 12.0
		vertical_look_ahead_distance = vp.size.y / 14.0 


func target_initialize(player: CharacterBody2D) -> void:
	target = player
	global_position = player.global_position
#extends Camera2D
#
#
#var target: Player
#var horizontal_look_ahead_distance: float
#var vertical_look_ahead_distance: float
#
#@export_group("Smoothing")
#@export var lead_speed: float = 5.0    
#@export var follow_speed: float = 10.0
#var target_offset: Vector2 = Vector2.ZERO
#
#func _ready():
	#viewport_size_change_callback()
	#get_viewport().size_changed.connect( viewport_size_change_callback )
#
#
#func _physics_process(delta: float) -> void:
	#if not target:
		#return
	#var desired_offset_x = get_persistent_direction() * horizontal_look_ahead_distance
	#target_offset.x = lerp(target_offset.x, desired_offset_x, lead_speed * delta)
	#var desired_position = target.global_position + target_offset
	#global_position = global_position.lerp(desired_position, follow_speed * delta)
#
#
#var last_direction: float = 1.0
#func get_persistent_direction() -> float:
	#var current_velocity = target.velocity.x
	#if not is_zero_approx(current_velocity):
		#last_direction = sign(current_velocity)
	#return last_direction
#
#
#func viewport_size_change_callback():
	#var vp = get_viewport()
	#horizontal_look_ahead_distance = vp.size.x / 12.0
	##vertical_look_ahead_distance = vp.size.y / 14.0
#
#
#func target_initialize( player: Player) -> void:
	#target = player
	#global_position = player.global_position
	##target.local_controller_added.connect( func(lc: LocalPlayerController):
		##local_controller_ref = lc)
	##target.started_falling.connect( func():
		##print("started falling")
		##)
