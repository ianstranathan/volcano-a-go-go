extends RefCounted
class_name EffectParameters

var type: Effects.EffectNames
var pos: Vector2
var flip: bool = false
var dir: Vector2 = Vector2.ZERO

# A quick helper constructor to make creating it a one-liner
func _init(_type: Effects.EffectNames, _pos: Vector2, _flip: bool = false, _dir: Vector2 = Vector2.ZERO):
	type = _type
	pos = _pos
	flip = _flip
	dir = _dir
