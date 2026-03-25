#get info from ItemManager and pass to hotbar_slot. redraws all slots every call. if standard item is null texture 
#remains null and that will tell the hotbar_slot.gd- set_slot_display to draw an empty slot. doing texture lookup here
#should i just pass it in?
extends Control
class_name HotbarUi

@onready var standard_slots = $HotBarWindow/StandardSlots.get_children()

@onready var special_slot: HotbarSlot = $HotBarWindow/SpecialSlot

func _ready() -> void:
	set_hotbar_display([], -1, null)

func set_hotbar_display(standard_items: Array, selected_index: int, special_item) -> void:
	for i in range(standard_slots.size()):
		var icon: Texture2D = null

		if i < standard_items.size() and standard_items[i] != null:
			icon = ItemsDb.get_texture(standard_items[i])

		standard_slots[i].set_slot_display(icon, i == selected_index)

	var special_icon: Texture2D = null
	if special_item != null:
		special_icon = ItemsDb.get_texture(special_item)

	special_slot.set_slot_display(special_icon, false)
