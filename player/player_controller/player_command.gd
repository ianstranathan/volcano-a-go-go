extends RefCounted
class_name PlayerCommand


var move_input: Vector2 = Vector2.ZERO
var jump_pressed := false
var jump_released := false
var aiming_input: Vector2 = Vector2.ZERO
var using_controller := false
var carrying_item := false
var item_use_pressed := false
var tick := 0

static var size_of_a_command: int = 21

func serialize() -> PackedByteArray:
	# -- 16 bytes
	var spb = StreamPeerBuffer.new()
	spb.put_float(move_input.x)
	spb.put_float(move_input.y)
	spb.put_float(aiming_input.x)
	spb.put_float(aiming_input.y)

	# -- bit shifting and OR-ing to
	# -- but all bools in 1 byte
	var flags := 0
	if jump_pressed:    flags |= 1 << 0
	if jump_released:   flags |= 1 << 1
	if using_controller: flags |= 1 << 2
	if carrying_item:   flags |= 1 << 3
	if item_use_pressed:   flags |= 1 << 4
	#if item_use_released:  flags |= 1 << 5
	spb.put_u8(flags)

	# -- 4 bytes
	spb.put_u32(tick)
	
	# -- 21 bytes total
	return spb.data_array


static func deserialize(byte_arr: PackedByteArray) -> PlayerCommand:
	var cmd = PlayerCommand.new()
	var spb = StreamPeerBuffer.new()
	spb.data_array = byte_arr

	cmd.move_input.x = spb.get_float()
	cmd.move_input.y = spb.get_float()
	cmd.aiming_input.x = spb.get_float()
	cmd.aiming_input.y = spb.get_float()

	# -- Unpack the booleans using bitwise AND
	var flags = spb.get_u8()
	cmd.jump_pressed    = bool(flags & (1 << 0))
	cmd.jump_released   = bool(flags & (1 << 1))
	cmd.using_controller = bool(flags & (1 << 2))
	cmd.carrying_item   = bool(flags & (1 << 3))
	cmd.item_use_pressed  = bool(flags & (1 << 4))
	#cmd.item_use_released = bool(flags & (1 << 5))
	
	cmd.tick = spb.get_u32()
	
	return cmd


static func serialize_list_of_commands(commands: Array[PlayerCommand]) -> PackedByteArray:
	var spb = StreamPeerBuffer.new()
	# -- num commands
	spb.put_u8(commands.size())
	for cmd in commands:
		spb.put_data(cmd.serialize())
	return spb.data_array


static func deserialize_list_of_commands(byte_arr: PackedByteArray) -> Array[PlayerCommand]:
	var cmds: Array[PlayerCommand] = []
	var spb = StreamPeerBuffer.new()
	spb.data_array = byte_arr
	var count = spb.get_u8()
	for i in range(count):
		# -- 21 byte slices
		# -- so, first byte is always the num of commands that we need to step over
		var offset_into_arr = 1 + (i * size_of_a_command)
		var end_of_byte_arr = 1 + ((i + 1) * size_of_a_command)
		var sub_arr = byte_arr.slice(offset_into_arr, end_of_byte_arr)
		cmds.append(PlayerCommand.deserialize(sub_arr))
	return cmds
