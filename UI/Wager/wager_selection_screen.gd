# Builds the list of currently available wager options and forwards the player's selection.
class_name WagerSelectionScreen
extends MarginContainer

signal wager_selected(wager: WagerData)

@export var wager_option_card_scene: PackedScene

@onready var wager_list: VBoxContainer = %WagerList


func setup(wagers: Array[WagerData]) -> void:
	_clear_wagers()

	for wager in wagers:
		var card: WagerOptionCard = wager_option_card_scene.instantiate()
		wager_list.add_child(card)

		card.setup(wager)
		card.wager_selected.connect(_on_wager_selected)


func _on_wager_selected(wager: WagerData) -> void:
	wager_selected.emit(wager)


func _clear_wagers() -> void:
	for child in wager_list.get_children():
		child.queue_free()
