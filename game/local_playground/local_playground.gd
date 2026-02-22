extends Node2D


func _ready() -> void:
	$Camera.target_initialize($"PlayersContainer/1")
	$WorldEffects.initialize_recurring_player_vfx()
