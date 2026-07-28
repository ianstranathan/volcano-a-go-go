@tool
extends Node2D

class_name DissolvingPlatformComponent
"""
Allegedly:
	Class-Level Sharing: Because var mat := preload(...) is defined outside of any function, 
	Godot loads dissolving_platform_mat.tres once when the script is parsed. 
	All instances of DissolvingPlatformComponent share the exact same material reference in memory.
"""

const DISSOLVE_MAT := preload("res://levels/platforms/platform_components/dissolving_platform_component/dissolving_platform_mat.tres")

@export var sprite: Sprite2D:
	set(v):
		sprite = v


@export var p: BasePlatform
@export var time_to_dissolve: float = 1.0
@export var time_to_reappear: float = 1.0

enum DissolveType{
	ONE_SHOT,
	MODULO,
	SNAP_BACK
}
@export var dissolve_type: DissolveType = DissolveType.MODULO
@onready var reappear_timer:TickTimer = TickTimer.new(time_to_reappear)

var _time := 0.0
var target_time:= 1.0
var time_direction := 1.0
var dissolving = false

func _enter_tree() -> void:
	# Run automatic detection in editor if not already assigned
	if Engine.is_editor_hint() and not sprite:
		get_base_platform_sprite()


func get_base_platform_sprite() -> void:
	p = get_parent() as BasePlatform
	assert(p is BasePlatform)
	
	if not p:
		return
	
	sprite = p.get_node_or_null("Sprite2D")
	
	if sprite:
		sprite.material = DISSOLVE_MAT.duplicate()
		sprite.material.set_shader_parameter("dissolve_progress", 0.)
	else:
		print("dissolved plat component; what is wrong with you....")


func _ready():
	if !Engine.is_editor_hint():
		get_base_platform_sprite()
		# -- inject base platforms area2d behavior
		var a = p.get_node_or_null("Area2D") as Area2D
		a.body_entered.connect( func(b): if b is Player:
			start_dissolving() )

		# -- Timer callback
		reappear_timer.timeout.connect( func():
			start_reappearing())


func start_dissolving():
	set_target_time(1.0)


func start_reappearing():
	set_target_time(0.0)


func set_target_time(target: float):
	var t = clampf(target, 0.0, 1.0)
	if t > _time:
		time_direction = 1.0
	elif t < _time:
		time_direction = -1.0
	dissolving = true
	target_time = t


var coll_shape_disabled := false
func execute_tick( delta: float) -> void:
	if dissolving and sprite:
		_time += time_direction * delta
		if _time <= time_to_dissolve and _time >= 0:
			var r = _time / time_to_dissolve
			sprite.material.set_shader_parameter("dissolve_progress", r)
			if _time > 0.75 and not coll_shape_disabled:
				p.disable_collisions( true )
				coll_shape_disabled = true
		else:
			dissolved_finished_resolution()


func dissolved_finished_resolution():
	dissolving = false # -- controls both dissolving and reappearing
	
	# -- if it has dissolved
	if is_equal_approx(_time, 1.):
		
		match dissolve_type:
			DissolveType.ONE_SHOT:
				pass
			DissolveType.MODULO:
				reappear_timer.start()
			DissolveType.SNAP_BACK:
				start_reappearing()
	# -- 
	else:
		coll_shape_disabled = false
		p.disable_collisions( false )
