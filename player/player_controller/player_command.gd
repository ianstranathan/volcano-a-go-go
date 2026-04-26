
extends RefCounted
class_name PlayerCommand

"""
DON"T FORGET ME
I think this makes some assumptions about endianess
so... this will mess up if it's not on the same hardware
"""

var move_input: Vector2 = Vector2.ZERO
var jump_pressed := false
var jump_released := false
var aiming_input: Vector2 = Vector2.ZERO
var using_controller := false
var carrying_item := false
var item_use_pressed := false
var item_use_held := false
var tick := 0

static var size_of_a_command: int = 21

#func serialize() -> PackedByteArray:
	## -- 16 bytes
	#var spb = StreamPeerBuffer.new()
	#spb.put_float(move_input.x)
	#spb.put_float(move_input.y)
	#spb.put_float(aiming_input.x)
	#spb.put_float(aiming_input.y)
#
	## -- bit shifting and OR-ing to
	## -- but all bools in 1 byte
	#var flags := 0
	#if jump_pressed:     flags |= 1 << 0
	#if jump_released:    flags |= 1 << 1
	#if using_controller: flags |= 1 << 2
	#if carrying_item:    flags |= 1 << 3
	#if item_use_pressed: flags |= 1 << 4
	#if item_use_held:    flags |= 1 << 5
	##if item_use_released:  flags |= 1 << 5
	#spb.put_u8(flags)
#
	## -- 4 bytes
	#spb.put_u32(tick)
	#
	## -- 22 bytes total
	#return spb.data_array
#
#
#static func deserialize(byte_arr: PackedByteArray) -> PlayerCommand:
	#var cmd = PlayerCommand.new()
	#var spb = StreamPeerBuffer.new()
	#spb.data_array = byte_arr
#
	#cmd.move_input.x = spb.get_float()
	#cmd.move_input.y = spb.get_float()
	#cmd.aiming_input.x = spb.get_float()
	#cmd.aiming_input.y = spb.get_float()
#
	## -- Unpack the booleans using bitwise AND
	#var flags = spb.get_u8()
	#cmd.jump_pressed    = bool(flags & (1 << 0))
	#cmd.jump_released   = bool(flags & (1 << 1))
	#cmd.using_controller = bool(flags & (1 << 2))
	#cmd.carrying_item   = bool(flags & (1 << 3))
	#cmd.item_use_pressed  = bool(flags & (1 << 4))
	#cmd.item_use_held = bool(flags & (1 << 5))
	#
	#cmd.tick = spb.get_u32()
	#
	#return cmd


static func serialize_list_of_commands(commands: Array[PlayerCommand]) -> PackedByteArray:
	var spb = StreamPeerBuffer.new()
	spb.put_u8(commands.size())

	for cmd in commands:
		spb.put_float(cmd.move_input.x)
		spb.put_float(cmd.move_input.y)
		spb.put_float(cmd.aiming_input.x)
		spb.put_float(cmd.aiming_input.y)

		var flags := 0
		if cmd.jump_pressed: flags |= 1 << 0
		if cmd.jump_released: flags |= 1 << 1
		if cmd.using_controller: flags |= 1 << 2
		if cmd.carrying_item: flags |= 1 << 3
		if cmd.item_use_pressed: flags |= 1 << 4
		if cmd.item_use_held:    flags |= 1 << 5
		spb.put_u8(flags)
		spb.put_u32(cmd.tick)

	return spb.data_array


static func deserialize_list_of_commands(byte_arr: PackedByteArray) -> Array[PlayerCommand]:
	# -- first byte is number of commands
	# -- bail out if no commands
	var cmds: Array[PlayerCommand] = []
	if byte_arr.size() < 1: 
		return cmds
	var spb = StreamPeerBuffer.new()
	spb.data_array = byte_arr
	
	var count = spb.get_u8()
	
	# -- defensive check; ensure the buffer is large enough for the claimed count
	# 22 bytes per command + 1 byte for the count
	var expected_size = 1 + (count * size_of_a_command)
	if byte_arr.size() < expected_size:
		print("Warning: Received truncated input packet")
		return cmds
	for i in range(count):
		var cmd = PlayerCommand.new()

		# ---- read fixed layout (size_of_a_command bytes per command)
		cmd.move_input.x = spb.get_float()
		cmd.move_input.y = spb.get_float()

		cmd.aiming_input.x = spb.get_float()
		cmd.aiming_input.y = spb.get_float()

		var flags = spb.get_u8()
		cmd.jump_pressed     = bool(flags & (1 << 0))
		cmd.jump_released    = bool(flags & (1 << 1))
		cmd.using_controller = bool(flags & (1 << 2))
		cmd.carrying_item    = bool(flags & (1 << 3))
		cmd.item_use_pressed = bool(flags & (1 << 4))
		cmd.item_use_held    = bool(flags & (1 << 5))
		cmd.tick = spb.get_u32()

		cmds.append(cmd)

	return cmds
