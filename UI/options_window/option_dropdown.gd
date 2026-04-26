extends HBoxContainer

signal item_selected(index: int, text: String)

@export var label_text: String = "Setting"

@onready var name_label: Label = $NameLabel
@onready var dropdown: OptionButton = $Dropdown


func _ready() -> void:
	name_label.text = label_text
	dropdown.item_selected.connect(_on_dropdown_item_selected)


func clear_items() -> void:
	dropdown.clear()


func add_item(text: String, id: int = -1) -> void:
	if id == -1:
		dropdown.add_item(text)
	else:
		dropdown.add_item(text, id)


func select_item_by_text(text: String) -> void:
	for i in range(dropdown.item_count):
		if dropdown.get_item_text(i) == text:
			dropdown.select(i)
			return


func get_selected_text() -> String:
	var index := dropdown.selected
	if index < 0:
		return ""
	return dropdown.get_item_text(index)


func _on_dropdown_item_selected(index: int) -> void:
	item_selected.emit(index, dropdown.get_item_text(index))
