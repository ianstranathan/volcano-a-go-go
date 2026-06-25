@tool
extends Node2D

@export var sync_component: SpriteCollisionSync
@export var end_pos: Vector2
@export var speed: float = 100
@onready var start_pos: Vector2 = global_position

@export var path_follow: PathFollow2D


func _ready() -> void:
	
	if path_follow:
		$AnimatableBody2D/MovingPlatformComponent._path_follower = path_follow


func execute_tick(delta: float):
	$AnimatableBody2D/MovingPlatformComponent.execute_tick(delta)



# Exported property in parent with setter/getter forwarding
@export var coll_extents: Vector2:
	set(value):
		if sync_component:
			sync_component.coll_extents = value  # forward to child
	get:
		return sync_component.coll_extents if sync_component else Vector2(50, 50)

@export var color: Color:
	set(value):
		if sync_component:
			sync_component.color = value
	get:
		return sync_component.color if sync_component else Color(1,1,1,1)
