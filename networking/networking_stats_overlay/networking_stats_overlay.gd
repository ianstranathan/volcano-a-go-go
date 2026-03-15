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
		stats += "Tick Speed: %.2f%%\n" % (NetManager.tick_speed_multiplier * 100.0)
		stats += "Clock Synced: %s\n" % str(NetManager.clock_synced)

		var diff = NetManager.current_tick - NetManager.last_host_tick
		stats += "Tick Lead: %d\n" % diff
	else:
		for id in NetManager.remote_input_buffers:
			var buffer = NetManager.remote_input_buffers[id]
			var cmd = buffer[NetManager.current_tick % NetManager.INPUT_BUFFER_SIZE]
			var buffer_diff = NetManager.current_tick - cmd.tick
			stats += "Peer %d Buffer Diff: %d\n" % [id, buffer_diff]

	label.text = stats
