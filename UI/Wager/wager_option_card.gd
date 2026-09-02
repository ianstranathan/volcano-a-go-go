# Displays one available WagerData entry in the wager-selection list.
class_name WagerOptionCard
extends Button

signal wager_selected(wager: WagerData)

@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel

var wager_data: WagerData


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(wager: WagerData) -> void:
	wager_data = wager

	name_label.text = wager.display_name
	description_label.text = wager.description


func _on_pressed() -> void:
	if wager_data == null:
		return

	wager_selected.emit(wager_data)
