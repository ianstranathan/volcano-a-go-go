@tool # This allows the script to run inside the editor!
extends Node2D

@export var swing_speed: float = 3.0           
@export_range(0, 90) var max_angle_deg: float = 45.0  # Driven by tool script
@export var phase_offset: float = 0.0          
@export var deflection_intensity: float = 12.0 
@export var rope_length: float = 200.0         # Driven by tool script
@export var trap_body: Area2D                  

@onready var mid_pivot: Marker2D = $Marker2D
@onready var line_2d: Line2D = $Line2D

var _time: float = 0.0

func _ready() -> void:
	_time = phase_offset
	
	# When the actual game starts, initialize based on where you dragged the bob
	if not Engine.is_editor_hint() and trap_body:
		# Calculate rope length from where you placed it
		rope_length = trap_body.position.length()
		
		# Calculate the starting angle from its 2D position vector
		# we use atan2(x, y) because 0 degrees points straight down (0, 1) in our setup
		var actual_start_angle = atan2(trap_body.position.x, trap_body.position.y)
		max_angle_deg = abs(rad_to_deg(actual_start_angle))
		
		# If you dragged it to the left, start the swing phase from the left peak
		if trap_body.position.x < 0:
			_time = -PI / 2.0
		else:
			_time = PI / 2.0

func _physics_process(delta: float) -> void:
	# IF WE ARE IN THE EDITOR: Just update visuals based on where you drag things
	if Engine.is_editor_hint():
		if trap_body and mid_pivot and line_2d:
			mid_pivot.position = trap_body.position / 2.0
			line_2d.clear_points()
			line_2d.add_point(Vector2.ZERO)       
			line_2d.add_point(mid_pivot.position)  
			line_2d.add_point(trap_body.position)
		return # Stop execution here so it doesn't swing in the editor window

	# IF THE GAME IS RUNNING: Normal physics swing code
	_time += delta * swing_speed
	
	var max_angle_rad = deg_to_rad(max_angle_deg)
	var def_intensity_rad = deg_to_rad(deflection_intensity)
	
	var main_angle = max_angle_rad * sin(_time)
	var def_angle = main_angle + (def_intensity_rad * cos(_time))

	trap_body.position = Vector2(
		sin(def_angle) * rope_length,
		cos(def_angle) * rope_length
	)

	mid_pivot.position = trap_body.position / 2.0

	line_2d.clear_points()
	line_2d.add_point(Vector2.ZERO)       
	line_2d.add_point(mid_pivot.position)  
	line_2d.add_point(trap_body.position) 

func _on_damage_zone_body_entered(body: Node2D) -> void:
	if not Engine.is_editor_hint() and body is Player: 
		if body.has_method("take_damage"):
			body.take_damage()
