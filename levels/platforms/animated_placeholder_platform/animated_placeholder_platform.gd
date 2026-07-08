@tool
extends Node2D

class_name MovingPlatformPlaceholder
@export var sync_component: SpriteCollisionSync
@export var speed: float = 100

@export var path_follow: PathFollow2D
@onready var moving_platform_component: MovingPlatformComponent = $AnimatableBody2D/MovingPlatformComponent

enum MoveType{
	OSCILLATE,
	LOOP,
	MODULO,
	ONE_SHOT
}

@export var transition_type: Tween.TransitionType = Tween.TRANS_LINEAR
@export var easing_type: Tween.EaseType = Tween.EASE_IN
@export var movement_type:MoveType = MoveType.LOOP

func _ready() -> void:
	assert(path_follow)
	assert($AnimatableBody2D/MovingPlatformComponent)
	if path_follow != null:
		$AnimatableBody2D/MovingPlatformComponent._path_follower = path_follow


func execute_tick(delta: float):
	$AnimatableBody2D/MovingPlatformComponent.execute_tick(delta)


func reverse():
	# -- set it to it's respective bounds
	$AnimatableBody2D/MovingPlatformComponent._time = (
		clamp($AnimatableBody2D/MovingPlatformComponent._time, 0., 1.))
	# -- and reverse the direction of incrementing delta 
	$AnimatableBody2D/MovingPlatformComponent.time_direction *= -1

# setter/getter forwarding
@export var coll_extents: Vector2:
	set(value):
		if sync_component:
			sync_component.coll_extents = value  # forward to child
	get:
		return sync_component.coll_extents if sync_component else Vector2(200, 100)

@export var color: Color:
	set(value):
		if sync_component:
			sync_component.color = value
	get:
		return sync_component.color if sync_component else Color(1,1,1,1)
