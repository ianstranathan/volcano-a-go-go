extends RefCounted
class_name PlayerState

var pos :Vector2 = Vector2.ZERO
var vel :Vector2 = Vector2.ZERO
var rot: float = 0.0
var movement_state: int = 0
var tick: int = -1

func serialize() -> PackedByteArray:
	var spb = StreamPeerBuffer.new()
	spb.put_float(pos.x)
	spb.put_float(pos.y)
	spb.put_float(vel.x)
	spb.put_float(vel.y)
	spb.put_float(rot)
	spb.put_32(movement_state)
	spb.put_32(tick)
	return spb.data_array


static func deserialize(byte_arr: PackedByteArray) -> PlayerState:
	var ps = PlayerState.new()
	var spb = StreamPeerBuffer.new()
	spb.data_array = byte_arr
	ps.pos.x = spb.get_float()
	ps.pos.y = spb.get_float()
	ps.vel.x = spb.get_float()
	ps.vel.y = spb.get_float()
	ps.rot = spb.get_float()
	ps.movement_state = spb.get_32()
	ps.tick = spb.get_32()
	return ps


func set_state(player: Player, _tick: int):
	pos = player.global_position
	vel = player.velocity
	rot = player.global_rotation
	movement_state = player.movement_state
	tick = _tick
