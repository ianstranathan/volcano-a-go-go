extends Node2D

# -- TODO There's no need to have the targetVisual as a separate scene



"""
This is just a "dumb" aiming visual, it's just a visual callback to the
item targeting something
e.g. grappling hook has a successful ray intersection check
it emits a signal with that intersection position
it percolates up and ends up connecting to update_aiming_visual
(player connects aiming visual to input manager on _ready() )

Timer:
	everytime there's input from the player's controller (specifically aiming)
	aiming visual toggle visibility and hide timer is started
"""
var line2d_2_max_range_or_target_fn: Callable
# -- this is the item's default max range
var target_position_for_line: Vector2 = Vector2.ZERO
@export var targeted_visual: Sprite2D:
	set(v):
		targeted_visual = v
		if $RaycastRelated/Line2D:
			line2d_2_max_range_or_target_fn = func():
				var p = (targeted_visual.global_position if targeted_visual.visible
					 else target_position_for_line)
				$RaycastRelated/Line2D.set_point_position(1, to_local( p ))

var should_show := false
var can_show := true


func _ready() -> void:
	assert(targeted_visual)
	hide()
	$LastUsedTimer.timeout.connect( func():
		set_physics_process(false)
		hide())


# -- the direction lines indicating aim
func update_aiming_visual( ):
	# -- this is a callback to the input manager detecting 
	# -- mouse input or controller R-stick input
	# -- (we want the aiming to hide after a certain amount of time)
	if can_show and should_show:
		set_physics_process(true)
		show()
		$LastUsedTimer.start()


# -- this is a callback from the item manager
func update_dir(pos: Vector2):
	if $RaycastRelated.visible:
		target_position_for_line = pos
	else:
		#print($ProjectileRelated.global_position)
		#print(global_position == $ProjectileRelated.global_position)
		#print((pos - global_position))
		#print("+++++++")
		point_and_offset_projectile_visual((pos - global_position).normalized())


# -- NOTE
# -- the aiming visual is connected via player (intermediary signal bus)
# -- the item tells it which way it's looking
func _physics_process(_delta: float) -> void:
	# -- raycast direction change
	if $RaycastRelated.visible:
		line2d_2_max_range_or_target_fn.call()
	else:
		pass

# -- the reticle / target pos indicating that you can do something
func update_target_pos(pos):
	if !should_show:
		should_show = true
	
	if $RaycastRelated.visible:
		update_ray_hit_indication(pos)


func update_ray_hit_indication(pos):
	# -- this is just changing the color of the line2d + toggling the hit star
	if pos:
		targeted_visual.visible = true
		$RaycastRelated/Line2D.material.set_shader_parameter("hit_modulation", 1.0)
		targeted_visual.global_position = pos
	else:
		$RaycastRelated/Line2D.material.set_shader_parameter("hit_modulation", 0.0)
		targeted_visual.visible = false


func toggle_ray_visual(b: bool):
	$RaycastRelated.visible = b


func toggle_projectile_visual(b: bool):
	$ProjectileRelated.visible = b


func handle_aim_type(aim_type: ItemManager.AimingTypes):
	pass
	match aim_type:
		ItemManager.AimingTypes.RAYCAST:
			toggle_ray_visual( true )
			toggle_projectile_visual( false )
			can_show = true
		ItemManager.AimingTypes.PROJECTILE:
			toggle_ray_visual( false )
			toggle_projectile_visual( true )
			can_show = true
		_:
			toggle_ray_visual( false )
			toggle_projectile_visual( false )
			can_show = false


func point_and_offset_projectile_visual(dir: Vector2) -> void:
	$ProjectileRelated/ProjectileAim.rotation = dir.angle()
	$ProjectileRelated/ProjectileAim.position = Vector2.RIGHT.rotated(dir.angle()) * 256
