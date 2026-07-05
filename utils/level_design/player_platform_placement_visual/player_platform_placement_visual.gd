@tool
extends Node2D

@export var stats: PlayerKinematicData

@export_group("Line2D References")
@export var right_regular_jump_arc: Line2D
@export var left_regular_jump_arc: Line2D
@export var right_wall_jump_arc: Line2D
@export var left_wall_jump_arc: Line2D

@export_group("Baking Settings")
## How many segments/points the Line2Ds will have
@export var resolution: int = 40

## The time interval (in seconds) between each point on the lines.
## Set this to 0.0167 to simulate exactly 60 FPS physics frames.
@export var time_step: float = 0.0167

## Click this checkbox in the Inspector to generate/bake all 4 lines simultaneously!
@export var bake_all_arcs: bool = false:
	set(value):
		if value == true:
			make_line_pts()
		bake_all_arcs = false


func make_line_pts() -> void:
	if not stats:
		print("Bake aborted: Missing PlayerKinematicData resource.")
		return

	# FORCE THE RESOURCE TO RECALCULATE RIGHT NOW IN THE EDITOR
	if stats.has_method("_recalculate_physics"):
		stats._recalculate_physics()
	
	# Print to the output log to verify the numbers are actually different!
	print("--- TRAJECTORY DIAGNOSTIC ---")
	print("Regular Velocity: ", Vector2(stats.baseline_speed, stats.jump_speed))
	print("Wall Jump Scale Vector: ", stats.wall_jump_scale)
		
	var lines = [right_regular_jump_arc, left_regular_jump_arc, right_wall_jump_arc, left_wall_jump_arc]
	for line in lines:
		if not line:
			print("Bake aborted: One or more Line2D references are missing.")
			return
		line.clear_points()

	# 2. Setup initial positions for all 4 paths (starting at local 0,0)
	var pos_reg_r = Vector2.ZERO
	var pos_reg_l = Vector2.ZERO
	var pos_wall_r = Vector2.ZERO
	var pos_wall_l = Vector2.ZERO

	# 3. Setup distinct initial velocities for each trajectory type
	# Regular jumps use baseline speed
	var vel_reg_r = Vector2(stats.baseline_speed, stats.jump_speed)
	var vel_reg_l = Vector2(-stats.baseline_speed, stats.jump_speed)
	
	# Wall jumps use the absolute values calculated in your resource.
	# Note: stats.wall_jump_scale.y is already negative because it derives from jump_speed.
	# For a wall jump to the right, X velocity must be positive (jumping AWAY from a left wall).
	var wall_vel_x = abs(stats.wall_jump_scale.x) 
	var wall_vel_y = stats.wall_jump_scale.y
	
	var vel_wall_r = Vector2(wall_vel_x, wall_vel_y)
	var vel_wall_l = Vector2(-wall_vel_x, wall_vel_y)

	# Cache delta squared for precise integration
	var step_sq = time_step * time_step

	# 4. Generate all paths in parallel through a single loop
	for i in range(resolution):
		# --- Step A: Record Current Positions ---
		right_regular_jump_arc.add_point(pos_reg_r)
		left_regular_jump_arc.add_point(pos_reg_l)
		right_wall_jump_arc.add_point(pos_wall_r)
		left_wall_jump_arc.add_point(pos_wall_l)

		# --- Step B: Determine Gravity State for each path ---
		var grav_reg_r = Vector2(0, stats.fall_gravity if vel_reg_r.y > 0 else stats.jump_gravity)
		var grav_reg_l = Vector2(0, stats.fall_gravity if vel_reg_l.y > 0 else stats.jump_gravity)
		var grav_wall_r = Vector2(0, stats.fall_gravity if vel_wall_r.y > 0 else stats.jump_gravity)
		var grav_wall_l = Vector2(0, stats.fall_gravity if vel_wall_l.y > 0 else stats.jump_gravity)

		# --- Step C: Update Positions (Precise Verlet Integration) ---
		pos_reg_r += (vel_reg_r * time_step) + (0.5 * step_sq * grav_reg_r)
		pos_reg_l += (vel_reg_l * time_step) + (0.5 * step_sq * grav_reg_l)
		pos_wall_r += (vel_wall_r * time_step) + (0.5 * step_sq * grav_wall_r)
		pos_wall_l += (vel_wall_l * time_step) + (0.5 * step_sq * grav_wall_l)

		# --- Step D: Advance Velocities for the Next Frame ---
		vel_reg_r += grav_reg_r * time_step
		vel_reg_l += grav_reg_l * time_step
		vel_wall_r += grav_wall_r * time_step
		vel_wall_l += grav_wall_l * time_step

	print("Baked all 4 jump paths across %d frames!" % resolution)
