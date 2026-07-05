@tool
extends Marker2D
class_name PickupEditorPlaceholder

# Expose your item enum directly to the inspector drop-down
@export var item_enum_type: ItemsDb.ItemNames = ItemsDb.ItemNames.values()[0]:
	set(value):
		item_enum_type = value
		queue_redraw() # Tells the editor to update the text display


func _ready() -> void:
	# If we are running the actual game (not the editor), we don't want 
	# this node wasting memory or processing ticks.
	if not Engine.is_editor_hint():
		queue_free()


# Visual feedback for designers inside the scene tab
func _draw() -> void:
	if Engine.is_editor_hint():
		# Draw a small circle where the pickup is centered
		draw_circle(Vector2.ZERO, 32.0, Color(0.428, 0.178, 0.583, 0.75))
		
		# FIX: Safely retrieve the default theme font via the engine's text server fallback
		var default_font: Font = ThemeDB.get_fallback_font()
		
		# String name of the item right above the marker
		var item_string_name = ItemsDb.ItemNames.keys()[item_enum_type]
		
		# Draw the string text
		draw_string(
			default_font, 
			Vector2(-75, -35), 
			item_string_name, 
			HORIZONTAL_ALIGNMENT_LEFT, 
			-1, 
			18, 
			Color.WHITE
		)
