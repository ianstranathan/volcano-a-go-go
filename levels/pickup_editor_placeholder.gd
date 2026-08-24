@tool
extends Marker2D
class_name PickupEditorPlaceholder


@export var item_enum_type: ItemsDb.ItemNames = ItemsDb.ItemNames.values()[0]:
	set(value):
		item_enum_type = value
		queue_redraw()


func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 32.0, Color(0.428, 0.178, 0.583, 0.75))
		var default_font: Font = ThemeDB.get_fallback_font()
		var item_string_name = ItemsDb.ItemNames.keys()[item_enum_type]
		draw_string(
			default_font, 
			Vector2(-75, -35), 
			item_string_name, 
			HORIZONTAL_ALIGNMENT_LEFT, 
			-1, 
			18, 
			Color.WHITE
		)
