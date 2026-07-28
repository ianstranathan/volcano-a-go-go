extends Node2D


@export var backgrond_layer: Node2D
@export var background_material: ShaderMaterial

@export var cam_ref: Camera2D :
	set(v):
		cam_ref = v

@export var scroll_speed_lvl_3 := Vector2(0.2, 0.2)

func _ready():
	assert(backgrond_layer)


func _process(_delta):
	if cam_ref:
		background_material.set_shader_parameter("camera_pos", cam_ref.global_position)
