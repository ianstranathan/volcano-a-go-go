extends Node

"""
"""
signal connection_failed

const ip = "127.0.0.1"
const PORT := 8910
const MAX_CLIENTS := 3


func host() -> void:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(PORT, MAX_CLIENTS) != OK:
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer


func join(_player_name: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(ip, PORT) != OK:
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer


func close_connection():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
