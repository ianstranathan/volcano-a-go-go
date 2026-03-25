extends Control

@onready var hotbar_ui: HotbarUi = $HudMargin/HudLayout/BottomArea/BottomCenter/CenterContainer/HotbarUi

func _ready() -> void:

	var test_items: Array = [
		ItemsDb.ItemNames.GRAPPLING_HOOK,
		ItemsDb.ItemNames.PARACHUTE,
		ItemsDb.ItemNames.ROPE,
		null,
		null
	]

	var test_special_item = ItemsDb.ItemNames.GRAPPLING_HOOK

	hotbar_ui.set_hotbar_display(test_items, 1, test_special_item)
