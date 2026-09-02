extends Resource

class_name DynamicObjectProfile

"""
cleaning up the dynamic object stuff to not make a mess

lives in db, e.g.:
	@export var profiles: Dictionary = {
	DynamicObjectType.ROCK: preload("res://levels/dynamic_objects/data/dynamic_rock.tres")
}

- placeholder accesses its texture data
- manager instances a dynamic object and it assigns the profile
"""
@export var type: DynamicObjectsDb.DynamicObjectType
@export var visual_scene: PackedScene
@export var collision_shape: Shape2D
@export var mass: float = 1.0
@export var friction: float = 0.5
@export var physics_script: Script
@export var grab_area_collision_shape: Shape2D
