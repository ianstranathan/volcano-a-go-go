#Keeping this as self contained as possible. should just update the visual component of the slot based on
#info passed in through set_slot_display. clear slot by passing a null texture. is that a good idea? probably not

extends Control
class_name HotbarSlot


@onready var selected_outline: Control = $SelectedOutline
@onready var icon: TextureRect = $MarginContainer/Icon


func _ready() -> void:
	selected_outline.visible = false


func set_slot_display(new_icon: Texture2D, is_selected: bool, _selected_outline_visible=false) -> void:
	if new_icon:
		icon.texture = new_icon
		icon.visible = true
		selected_outline.visible = is_selected
	else:
		icon.visible = false
		selected_outline.visible = false
	
	# -- picking up first item (when inventory is empty, i.e. array of enums
	# -- passed size == 1) we want to indicate that you're auto picking up
	# -- this seemed easier than adding more signals and connections to item_manager
	#if selected_outline_visible:
		#selected_outline.visible = true
