@tool
class_name PlayerKinematicData
extends Resource

# ------------------------------ Primary Core Values
@export var baseline_speed: float = 435.0:
	set(value):
		baseline_speed = value
		_recalculate_physics()

@export var mass: float = 1.0:
	set(value):
		mass = value
		inv_mass = 1.0 / mass if mass != 0 else 0.0

# General idea: lerp for overspeed, move_toward for underspeed
# trying to follow mario's lead:
# Air Accel: Low (around 1:3 of ground). Once you jump, you are committed to the arc.
# Turn Accel: Moderate (creates a distinct, satisfying sliding "skid" animation before reversing direction).

# -----------------------------  ACCELERATIONS
@export var ground_accl = 80.0
#@export var ground_turn_accl = 4.0 * ground_accl # -- full ground turn accl
@export var air_accl = ground_accl / 3.0

# -- target speeds as a ratio of baseline speed
@export var running_2_baseline_ratio: float = 1.6
@export var crouching_2_baseline_ratio: float = 0.5
@export var climbing_2_baseline_ratio: float = 0.7

# -----------------------------  DECELERATIONS
#@export var ground_decl = 0.8 * ground_accl
@export var air_decl = air_accl

# -----------------------------  Lerp percentages

# &
# -- ground_decl
# -- air_decl
# -- ground_turning_decl
# -- air_turning_decl

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
var crouching_speed: float


func _init() -> void:
	_recalculate_physics()


func _recalculate_physics() -> void:
	v_x_peak_2_fall = baseline_speed * 0.75
	climb_speed = baseline_speed * climbing_2_baseline_ratio
	inv_mass = 1.0 / mass if mass != 0 else 0.0
	crouching_speed = baseline_speed * crouching_2_baseline_ratio
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
