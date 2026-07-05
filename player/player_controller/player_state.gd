extends RefCounted
class_name PlayerState

var pos :Vector2 = Vector2.ZERO
var vel :Vector2 = Vector2.ZERO
var rot: float = 0.0
var movement_state: int = 0
var tick: int = -1
var is_on_platform: bool = false
# NOTE
# -- this will break or will require a manager of some kind if platforms are
# -- created dynamically (outside of scene assembly)
# -- right now all the moving paltforms are in the scene
var platform_id: int = -1 # -- for lookup in LevelManager
var local_pos: Vector2 = Vector2.ZERO

# -- we're looking this up at runtime (machine / authority specific)
var platform: MovingPlatformComponent = null 


func serialize() -> PackedByteArray:
	var spb = StreamPeerBuffer.new()
	spb.put_float(pos.x)
	spb.put_float(pos.y)
	spb.put_float(vel.x)
	spb.put_float(vel.y)
	spb.put_float(rot)
	spb.put_32(movement_state)
	spb.put_32(tick)
	# -- NOTE 7 more bools can fit here if we make more stff
	spb.put_u8(is_on_platform)
	spb.put_32(platform_id)
	spb.put_float(local_pos.x)
	spb.put_float(local_pos.y)
	
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
	ps.is_on_platform = spb.get_u8()
	ps.platform_id = spb.get_32()
	ps.local_pos.x = spb.get_float()
	ps.local_pos.y = spb.get_float()
	return ps


func set_state(player: Player, _tick: int) -> void:
	pos = player.global_position
	vel = player.velocity
	rot = player.global_rotation
	movement_state = player.movement_state
	is_on_platform = true if player.current_platform_displacement_ref else false
	tick = _tick
	
	if player.current_platform_displacement_ref:
		is_on_platform = true
		var _platform = player.current_platform_displacement_ref
		# -- NOTE this breaks if we ever do dynamic platforming
		# -- or rather it'd incur a manager to assign unique ids / have some lookup system
		platform_id = _platform.network_id
		local_pos = _platform.to_local(player.global_position)
		# -- to_local docs:
		#Transforms the provided local position into a position in global coordinate space. 
		#The input is expected to be local relative to the Node2D it is called on. e.g. 
		#Applying this method to the positions of child nodes will correctly transform their positions 
		#into the global coordinate space, but applying it to a node's own position 
		#will give an incorrect result, as it will incorporate the node's own 
		#transformation into its global position.
	else:
		is_on_platform = false
		platform_id = -1
		local_pos = Vector2.ZERO


func copy_state(another_state: PlayerState):
	pos = another_state.pos
	vel = another_state.vel
	rot = another_state.rot
	movement_state = another_state.movement_state
	tick = another_state.tick
	is_on_platform = another_state.is_on_platform
	platform_id = another_state.platform_id
	local_pos = another_state.local_pos


func clear_state() -> void:
	pos = Vector2.ZERO
	vel = Vector2.ZERO
	rot = 0.0
	movement_state = 0
	tick = -1
	is_on_platform = false
	platform_id = -1
	local_pos = Vector2.ZERO
