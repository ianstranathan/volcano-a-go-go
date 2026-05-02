extends Node2D

class_name VolcanoBackgroundTile

"""
This is a tile to act as a chunk in a seamless tiling of a shader that
uses world uvs

- scales sprite to given tile size

TODO
Does disabling the render keep the shader from pulling in uniforms?
"""

# -- just so I don't have to instance one to get this number
static var tile_size: Vector2 = Vector2(2048, 2048)


func _ready() -> void:
	var _sprite_size = GeneralUtils.sprite_size( $Sprite2D )
	# -- scale sprite to fit tile size
	$Sprite2D.scale =  tile_size / _sprite_size
	
	# -- if the tile goes offscreen, we shouldn't render it
	# -- this doesn't affect networked gameplay as the rendering is only happening
	# -- for a local client

	#$VisibleOnScreenNotifier2D.screen_exited.connect( func():
		#visible = false)
#
	#$VisibleOnScreenNotifier2D.screen_entered.connect( func():
		#visible = true)

func set_level_dimensions(dims: Vector2):
	$Sprite2D.material.set_shader_parameter( "level_dims", dims)


func set_shader_parameter_wrapper(str: String, val):
	$Sprite2D.material.set_shader_parameter(str, val)
