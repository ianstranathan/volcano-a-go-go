#Keeping this as self contained as possible. should just update the visual component of the slot based on
#info passed in through set_slot_display. clear slot by passing a null texture. is that a good idea? probably not

extends Control
class_name HotbarSlot


@onready var selected_outline: Control = $SelectedOutline
@onready var icon: TextureRect = $MarginContainer/Icon


var active_icon_texture: Texture2D = null
var is_selected := false

func _ready() -> void:
	_update_slot()
	
func set_slot_display(new_icon: Texture2D, selected: bool) -> void:
	active_icon_texture = new_icon
	is_selected = selected
	_update_slot()
	
func _update_slot() -> void:
	selected_outline.visible = is_selected

	if active_icon_texture == null:
		icon.texture = null
		icon.visible = false
		return

	icon.texture = active_icon_texture
	icon.visible = true
