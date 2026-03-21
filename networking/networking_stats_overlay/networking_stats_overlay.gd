extends Control

@onready var label = $Label

func _process(_delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		label.text = "Not Connected"
		return
	
	var stats = ""
	stats += "Role: %s\n" % ("Host" if multiplayer.is_server() else "Client")
	stats += "Tick: %d\n" % NetManager.current_tick
	
	if !multiplayer.is_server():
		# -- diif compared to the last host packet
		stats += "Tick Speed: %.2f%%\n" % (NetManager.tick_multiplier() * 100.0)
		stats += "Tick offset from ideal: %d\n" % NetManager.tick_error
		stats += "Clock Synced: %s\n" % str(NetManager.clock_synced)
	else:
		pass
	label.text = stats
