@tool
extends Node2D
class_name DynamicObjectPlaceholder


@export var dynamic_object_type: DynamicObjectsDb.DynamicObjectType:
	set(value):
		dynamic_object_type = value
		if is_node_ready():
			_update_placeholder()

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()


func _update_placeholder() -> void:
	sprite.texture = DynamicObjectsDb.ROCK_ATLAS#ROCK_ATLAS
	sprite.region_enabled = true
	sprite.region_rect = DynamicObjectsDb.ROCK_ATLAS_REGIONS[dynamic_object_type]
	
