#Keeping this as self contained as possible. should just update the visual component of the slot based on
#info passed in through set_slot_display. clear slot by passing a null texture. is that a good idea? probably not

extends Control
class_name HotbarSlot


@onready var selected_outline: Control = $SelectedOutline
@onready var icon: TextureRect = $MarginContainer/Icon


func _ready() -> void:
	selected_outline.visible = false


func set_slot_display(new_icon: Texture2D, is_selected: bool) -> void:
	if new_icon:
		icon.texture = new_icon
		icon.visible = true
	else:
		icon.visible = false
	selected_outline.visible = is_selected
