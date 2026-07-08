#@tool
#
extends Node2D
#
#class_name MetaballPlatform
#
## TODO modularize animated vs static, should be able to be both
## - scale of circ radius in shader needs to scale evenly
#"""
#We need to gaurentee that we have enough working space to
#do the shader visual
#=> sprite has to be X amt bigger than the underlying collision geometry
#
#let's just do factor of two, so we know where we're at in the shader
#(this is $SpriteCollisionSync, there's just a scaling factor there)
#"""
#
## Backing variables for setters
#var _coll_extents: Vector2 = Vector2(50, 50)
#@export var _path_follow: PathFollow2D
#@export var coll_body:  PhysicsBody2D # -- static or animated
#func _ready() -> void:
	#assert( coll_body )
	#coll_body.add_to_group("metaball_platforms")
	#
	## -- 
	#assert(_path_follow)
	#
	#$SpriteCollisionSync.coll_extents = coll_extents
	#$AnimatedPlaceholderPlatform/Sprite2D.material.set_shader_parameter(
		#"coll_extents", coll_extents
	#)
#
#
#@export var coll_extents: Vector2:
	#set(value):
		#_coll_extents = value
		#coll_extents = _coll_extents
		#if is_node_ready():
			#$SpriteCollisionSync.coll_extents = coll_extents
			#$AnimatedPlaceholderPlatform/Sprite2D.material.set_shader_parameter(
				#"coll_extents", coll_extents
			#)
		##_update_collision_shape()
		##_update_sprite_scale()
	#get:
		#return _coll_extents
#
#
#func get_platform_transform() -> Transform2D:
	#return $AnimatedPlaceholderPlatform/AnimatableBody2D.transform
#
#
#func get_rect_shape() -> Vector2:
	#return coll_extents
