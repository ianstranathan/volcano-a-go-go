#get info from ItemManager and pass to hotbar_slot. redraws all slots every call. if standard item is null texture 
#remains null and that will tell the hotbar_slot.gd- set_slot_display to draw an empty slot. doing texture lookup here
#should i just pass it in?
extends Control
class_name HotbarUi

@onready var standard_slots = $HotBarWindow/StandardSlots.get_children()
@onready var special_slot: HotbarSlot = $HotBarWindow/SpecialSlot

func _ready() -> void:
	# -- connect to input manager changing item selection
	Events.inventory_changed.connect( set_inventory_display )
	# -- initialize inventory display
	#set_inventory_display([], -1, null)


func set_inventory_display(item_db_enums: Array, selected_index: int, special_item) -> void:
	"""
	Needs an array of enums from ItemDb
	"""
	# -- do standard items
	for i in range(standard_slots.size()):
		if item_db_enums[i] != -1:
			standard_slots[i].set_slot_display(ItemsDb.get_texture(item_db_enums[i]),
											   i == selected_index) # -- is selected
	# -- do special item
	if special_item != null:
		special_slot.set_slot_display(ItemsDb.get_texture(special_item),
									  false)
	
