@tool
extends Node2D
class_name DynamicObjectPlaceholder
var sprite: Sprite2D
@export var dynamic_object_type: DynamicObjectsDb.DynamicObjectType:
	set(value):
		dynamic_object_type = value
		if is_node_ready():
			_update_visuals()


func _ready() -> void:
	# -- just deletes itself to be replaced with the actual obj
	if not Engine.is_editor_hint():
		queue_free()
	# -- set visuals
	else:
		if !sprite:
			sprite = Sprite2D.new()
			add_child( sprite )
		_update_visuals()


func _update_visuals() -> void:
	var profile = DynamicObjectsDb.get_profile(dynamic_object_type)
	assert(profile.visual_scene)
	add_child( profile.visual_scene.instantiate() )
