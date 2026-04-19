extends Node2D

class_name PlayerVisualInterpolator
"""
Basic component to decouple visual from networked simulation
(to try to make things look smoother)
NOTE
It's hardcoded right now to only use with player, but this should probably
be generalized eventually
- being used on item_manager & player sprite
"""

@onready var p = get_parent()
@export var player_ref: Player

func _ready() -> void:
	p.set_as_top_level(true)


func _process(_delta: float) -> void:
	var pos_a = player_ref.pos_previous
	var pos_b = player_ref.pos_current
	p.global_position = pos_a.lerp(pos_b, NetManager.fract_tick)
