extends Label

@onready var DEBUG = $"../../../../..".DEBUG


func _ready() -> void:
	if !DEBUG:
		set_physics_process( false )
		visible = false

# -- no need to burn unecessary cycles in process for simple debug information
func _physics_process(_delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		text = "Not Connected"
		return
	
	var stats = ""
	stats += "Role: %s\n" % ("Host" if multiplayer.is_server() else "Client")
	stats += "Tick: %d\n" % NetManager.current_tick
	
	if !multiplayer.is_server():
		# -- diif compared to the last host packet
		# -- TODO assert that tick_multiplier is pure function
		stats += "Tick Speed: %.2f%%\n" % (NetManager.overlay_tick_multiplier * 100.0)
		stats += "Tick: average_offset - ideal_tick_lead: %d\n" % NetManager.tick_error()
		stats += "Clock Synced: %s\n" % str(NetManager.clock_synced)
	else:
		pass
	text = stats
