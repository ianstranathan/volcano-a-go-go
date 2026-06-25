@tool
class_name PlayerKinematicData
extends Resource

# ------------------------------ Primary Core Values
@export var baseline_speed: float = 380.0:
	set(value):
		baseline_speed = value
		_recalculate_physics()

@export var mass: float = 1.0:
	set(value):
		mass = value
		inv_mass = 1.0 / mass if mass != 0 else 0.0

@export var MOV_ACCL: float = 50.0
@export var TURN_ACCL: float = 500.0
@export var DECL: float = 40.0
@export var AIR_DECL: float = 10.0
@export var TERMINAL_FALL_SPEED: float = 1400.0

@export var jump_height: float = 200.0:
	set(value):
		jump_height = value
		_recalculate_physics()

@export var jump_distance_to_peak: float = 120.0:
	set(value):
		jump_distance_to_peak = value
		_recalculate_physics()

@export var fall_distance_from_peak: float = 100.0:
	set(value):
		fall_distance_from_peak = value
		_recalculate_physics()

@export var somersault_factor: float = 1.2
#@export var ledge_climb_duration := 0.6

var inv_mass: float = 1.0
var v_x_peak_2_fall: float = 0.0
var time_to_peak: float = 0.0
var time_to_ground: float = 0.0
var jump_gravity: float = 0.0
var fall_gravity: float = 0.0
var wall_slide_gravity: float = 0.0
var jump_speed: float = 0.0
var climb_speed: float = 0.0
var wall_jump_scale: Vector2

func _init() -> void:
	_recalculate_physics()


func _recalculate_physics() -> void:
	v_x_peak_2_fall = baseline_speed * 0.75
	climb_speed = baseline_speed * 0.7
	inv_mass = 1.0 / mass if mass != 0 else 0.0
	
	if baseline_speed > 0 and v_x_peak_2_fall > 0:
		time_to_peak = jump_distance_to_peak / baseline_speed
		time_to_ground = fall_distance_from_peak / v_x_peak_2_fall
	else:
		time_to_peak = 0.1
		time_to_ground = 0.1

	if time_to_peak > 0:
		jump_gravity = (2.0 * jump_height) / (time_to_peak * time_to_peak)
		jump_speed = -2.0 * jump_height / time_to_peak
		wall_jump_scale = Vector2(jump_speed / 2.0, jump_speed / 1.3)
		
	if time_to_ground > 0:
		fall_gravity = (2.0 * jump_height) / (time_to_ground * time_to_ground)
		wall_slide_gravity = fall_gravity / 100.0
	
	
	# Notify the editor/game that properties changed (useful for debugging)
	notify_property_list_changed()
