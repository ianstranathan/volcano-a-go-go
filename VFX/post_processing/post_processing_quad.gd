extends Sprite2D


@export var cam: Camera2D
@export var lava_ref: TheLava
var lava_data: Dictionary

func _ready() -> void:
	assert(cam)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_scale_to_viewport()


func _on_viewport_size_changed() -> void:
	_scale_to_viewport()


func _scale_to_viewport() -> void:
	var viewport_size = get_viewport().size
	var v = Vector2(float(viewport_size.x), float(viewport_size.y)) / cam.zoom
	var tex_size = texture.get_size()
	scale = v / tex_size

#func _ready() -> void:
	#assert(cam)
	## -- scale the quad to be the size of the vp
	#var viewport_size = get_viewport().size
	#var v = Vector2(float(viewport_size.x), float(viewport_size.y)) / cam.zoom
	#var tex_size = texture.get_size()
	#scale = v / tex_size


func execute_tick(_delta: float) -> void:
	if cam:
		global_position = cam.global_position
	
	if lava_ref:
		material.set_shader_parameter("lava_level", lava_ref.global_position.y)
		material.set_shader_parameter("sc", lava_ref.sinusoid_coeffs)
