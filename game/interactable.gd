# Reusable interaction point for world objects.
# The component handles interaction range/prompt and emits intent,
# while the owning object decides what the interaction actually does.
#may need some kind of overlap protection built eventually
@tool
class_name Interactable
extends Area2D

signal interacted(interactor: Node)

@export var prompt_text: String = "Interact"
@export var interaction_enabled: bool = true
@export_range(10.0, 500.0, 5.0) var interaction_radius: float = 60.0:
	set(value):
		interaction_radius = value
		var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision != null and collision.shape is CircleShape2D:
			collision.shape.radius = value		
		
@onready var prompt: Label = %Prompt

var current_interactor: Player


func _ready() -> void:
	prompt.hide()
	_update_prompt()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact() -> void:
	if not interaction_enabled or current_interactor == null:
		return

	interacted.emit(current_interactor)


func show_prompt() -> void:
	if not interaction_enabled:
		return

	_update_prompt()
	prompt.show()


func hide_prompt() -> void:
	prompt.hide()


func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled

	if not interaction_enabled:
		hide_prompt()


func _update_prompt() -> void:
	prompt.text = "[E] %s" % prompt_text


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	# Each client should only react to its own local player entering the area.
	if not body.is_multiplayer_authority():
		return

	if body.input_manager == null:
		return

	current_interactor = body
	body.input_manager.set_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	if body != current_interactor:
		return

	if body.input_manager != null:
		body.input_manager.clear_interactable(self)

	current_interactor = null
