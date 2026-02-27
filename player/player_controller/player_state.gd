extends RefCounted
class_name PlayerState

var pos :Vector2 = Vector2.ZERO
var vel :Vector2 = Vector2.ZERO
var tick := 0

func serialize() -> PackedByteArray:
	var spb = StreamPeerBuffer.new()
	spb.put_float(pos.x)
	spb.put_float(pos.y)
	spb.put_float(vel.x)
	spb.put_float(vel.y)
	spb.put_u32(tick)
	return spb


static func deserialize(byte_arr: PackedByteArray) -> PlayerCommand:
	var ps = PlayerState.new()
	var spb = StreamPeerBuffer.new()
	spb.data_array = byte_arr
	ps.pos.x = spb.get_float()
	ps.pos.y = spb.get_float()
	ps.vel.x = spb.get_float()
	ps.vel.y = spb.get_float()
	ps.tick = spb.get_u32()
	return ps
