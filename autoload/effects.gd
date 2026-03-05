extends Node

enum EffectNames {
	LANDING_SMOKE,
	DIRECTION_CHANGE,
	WALL_JUMP
}
var effects = {
	EffectNames.LANDING_SMOKE: preload("res://VFX/player effects/landing_smoke_sprite/landing_smoke_sprite.tscn"),
	EffectNames.DIRECTION_CHANGE: preload("res://VFX/player effects/direction_change/direction_change_1.tscn"),
	EffectNames.WALL_JUMP: preload("res://VFX/player effects/wall_jump_sprite/wall_jump_sprite.tscn")
}
