class_name WagerData
extends RefCounted

var id: StringName
var display_name: String
var description: String


func _init(
	p_id: StringName = &"",
	p_display_name: String = "",
	p_description: String = ""
) -> void:
	id = p_id
	display_name = p_display_name
	description = p_description
