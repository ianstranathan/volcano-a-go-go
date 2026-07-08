@tool
extends Node2D
class_name MetaballPlatformComponent

"""
What's actually required to be a metaball platform?
It's just the shader
The metaball manager on the player takes care of the logic,
we just need to be able to send the sprite some uniforms
"""
@export var sprite: Sprite2D

# Preload your specific metaball shader material
const METABALL_MATERIAL = preload(
"res://levels/platforms/platform_components/metaball_platform_component/metaball_material.tres")

# Keep track of the original material so we can restore it if the component is removed
var original_material: Material

func _ready() -> void:
	var p = get_parent() as BasePlatform
	#if Engine.is_editor_hint():
	p.sprite_2_coll_factor = 2.0
	_apply_metaball()


func _exit_tree() -> void:
	# Clean up and restore the original look if the component is deleted/removed
	_restore_original()

func _apply_metaball() -> void:
	var p = get_parent() as BasePlatform
	var s = p.get_node_or_null("Sprite2D")
	if s and s is CanvasItem:
		if not original_material:
			original_material = s.material
		
		# Duplicate the material so instances don't bleed into each other
		var m : ShaderMaterial = METABALL_MATERIAL.duplicate()
		m.set_shader_parameter("coll_extents", p.coll_extents)
		s.material = m


func _restore_original() -> void:
	var s = get_parent().get_node_or_null("Sprite2D")
	if s is CanvasItem and s.material != original_material:
		s.material = original_material
