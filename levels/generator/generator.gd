@tool
extends Node2D

@export_group("Generator Setup")
## Drop your Player character scene or script here to pull kinematics dynamically
@export var player_script: Script:
	set(value):
		player_script = value
		# -- docs
		# property_list_changed signal. 
		# This is mainly used to refresh the editor, so that the Inspector and editor plugins are properly updated.
		notify_property_list_changed()
		
		update_kinematics_from_player()

## Trigger a visual preview of the jump limits directly in the Godot viewport
@export var preview_generation_bounds: bool = false:
	set(value):
		preview_generation_bounds = value
		queue_redraw()

@export_group("Platform Prefabs")
@export var platform_prefab: PackedScene
@export var level_width: float = 800.0

# Dynamic kinematic values pulled from the player script
var player_baseline_speed: float
var player_v_x_peak_to_fall: float
var player_jump_height: float
var player_jump_distance_to_peak: float
var player_fall_distance_from_peak: float

# Calculated generation constraints
var max_jump_height: float = 0.0
var max_horizontal_reach: float = 0.0
var generation_warning: String = ""

func _ready() -> void:
	update_kinematics_from_player()

## Uses Godot's script property inspection to pull values without instantiating a node
func update_kinematics_from_player() -> void:
	if not player_script:
		generation_warning = "No Player Script attached!"
		return
		
	# Instantiating a dummy script object allows us to read default values securely
	var dummy = player_script.new()
	if dummy:
		player_baseline_speed = dummy.get("baseline_speed")
		player_v_x_peak_to_fall = dummy.get("v_x_peak_2_fall")
		player_jump_height = dummy.get("jump_height")
		player_jump_distance_to_peak = dummy.get("jump_distance_to_peak")
		player_fall_distance_from_peak = dummy.get("fall_distance_from_peak")
		
		# Free the dummy object from memory immediately
		dummy.free()
		
		calculate_reach_bounds()
		generation_warning = ""
	else:
		generation_warning = "Failed to parse player script variables."

func calculate_reach_bounds() -> void:
	if player_baseline_speed == 0 or player_v_x_peak_to_fall == 0: 
		return
		
	var time_to_peak = player_jump_distance_to_peak / player_baseline_speed
	var time_to_ground = player_fall_distance_from_peak / player_v_x_peak_to_fall
	
	max_jump_height = player_jump_height
	max_horizontal_reach = player_jump_distance_to_peak + (player_v_x_peak_to_fall * time_to_ground)
	
	# Force the editor view to redraw our visualization bounds if active
	if Engine.is_editor_hint():
		queue_redraw()

### Visualizer: Draws the calculated reach zone directly in your 2D editor viewport
#func _draw() -> void:
	#if not Engine.is_editor_hint() or not preview_generation_bounds:
		#return
		#
	## Draw a bounding box from the center representing the legal reach zone
	#var center = Vector2(level_width / 2.0, 0)
	#var box_size = Vector2(max_horizontal_reach * 2.0, max_jump_height)
	#var box_rect = Rect2(center.x - max_horizontal_reach, -max_jump_height, box_size.x, box_size.y)
	#
	## Draw a semi-transparent green box representing the safe generation window
	#draw_rect(box_rect, Color(0, 1, 0, 0.15), true)
	#draw_rect(box_rect, Color(0, 1, 0, 0.5), false, 2.0)
	#
	## FIX: Instantiating a temporary control node to safely fetch the editor/project default font
	#var temp_control = Control.new()
	#var default_font = temp_control.get_theme_font("font")
	#var font_size = temp_control.get_theme_font_size("font_size")
	#temp_control.free() # Always clean up memory in tool scripts
	#
	#draw_string(
		#default_font, 
		#center + Vector2(-100, -max_jump_height - 10), 
		#"Safe Jump Zone Preview", 
		#HORIZONTAL_ALIGNMENT_CENTER,
		#-1, # Width (-1 defaults to fully displaying the text)
		#font_size
	#)
#
## Configuration warnings display in the Godot Scene Tree dock if something is wrong
#func _get_configuration_warnings() -> PackedStringArray:
	#var warnings = PackedStringArray()
	#if not player_script:
		#warnings.append("Please assign the Player Script to the Level Generator to enable kinematic calculations.")
	#return warnings
