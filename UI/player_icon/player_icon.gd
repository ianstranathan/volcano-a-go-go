extends Control



func change_turban_color(col: Color) -> void:
	$TextureRect.material.set_shader_parameter("turban_color", col)


func change_icon_skin_tone(skin_enum:int) -> void:
	assert(skin_enum > 0 and skin_enum < 6) # -- only 5 skin tones
	$TextureRect.material.set_shader_parameter("skin_tone_type", skin_enum)

func change_placement_number_label( num: int):
	$Label.text = str( num )
