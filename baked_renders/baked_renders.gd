extends Node

@onready var sub_viewport: SubViewport = $SubViewport


func _ready() -> void:
	sub_viewport.transparent_bg = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	resize_viewport_to_sprite()
	
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	
	bake_to_image()


func resize_viewport_to_sprite() -> void:
	# Find the first Sprite2D child inside the SubViewport
	var sprite: Sprite2D = null
	for child in sub_viewport.get_children():
		if child is Sprite2D:
			sprite = child
			break
			
	if sprite and sprite.texture:
		# Get the pixel dimensions of the texture
		var texture_size: Vector2 = sprite.texture.get_size()
		
		# If you are scaling the sprite via sprite.scale, multiply it here:
		var final_size: Vector2 = texture_size * sprite.scale
		
		# Set the SubViewport size (needs to be Vector2i integers)
		sub_viewport.size = Vector2i(final_size)
		
		# Optional: Ensure the sprite is centered properly within the resized viewport
		if sprite.centered:
			sprite.position = final_size / 2
		else:
			sprite.position = Vector2.ZERO
	else:
		push_warning("No Sprite2D with a valid texture found under SubViewport.")


func bake_to_image():
	var viewport_texture: ViewportTexture = sub_viewport.get_texture()
	var image: Image = viewport_texture.get_image()
	# Note: Viewport textures are usually flipped upside down. 
	# You will likely want to uncomment this line:
	#image.flip_y() 
	
	var save_path = "res://baked_renders/baked.png"
	
	# Ensure the directory exists before saving
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("baked_renders"):
		dir.make_dir("baked_renders")
		
	var error = image.save_png(save_path)
	
	if error == OK:
		print("Successfully baked image saved to: ", ProjectSettings.globalize_path(save_path))
	else:
		print("Failed to save image. Error code: ", error)
