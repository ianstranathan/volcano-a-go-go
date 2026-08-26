class_name Genie
extends Node2D

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)

func _on_interacted(_interactor: Node) -> void:
	Events.wager_window_requested.emit()
