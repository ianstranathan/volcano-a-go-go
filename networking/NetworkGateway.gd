
extends Node


"""
TODO
- await seems brittle
"""
signal connection_failed

enum BackendType
{ 
	ENET,
	STEAM
}
var backend_type = BackendType.ENET
var active_backend: Node

# -- asserting backend components have:
# -- close_connection, join, host
func _ready():
	switch_to_backend(backend_type)

func leave() -> void:
	if active_backend:
		active_backend.close_connection()
	multiplayer.multiplayer_peer = null 


func switch_to_backend(type: BackendType):
	if active_backend:
		active_backend.queue_free()
 	
	match type:
		BackendType.STEAM:
			active_backend = load("res://networking/backends/SteamBackend.gd").new()
		BackendType.ENET:
			active_backend = load("res://networking/backends/ENetBackend.gd").new()
	backend_type = type
	active_backend.name = "NetworkComponent"
	active_backend.connection_failed.connect( func():
		# -- if a player fails to connect in host or join in ENet backend
		# -- or _on_lobby_match_list or _on_lobby_created in Steam backend
		# -- tell lobby accordingly
		connection_failed.emit())
	add_child(active_backend)
	
	# Check if we need to wait for the node to enter the tree
	if not active_backend.is_node_ready():
		await active_backend.ready


func host(player_name: String):
	if active_backend == null:
		await switch_to_backend(backend_type)
	NetManager.local_player_name = player_name
	NetManager.player_data[1] = NetManager.create_player_entry(player_name, 0)
	active_backend.host()
	NetManager.player_info_updated.emit(1, player_name, 0)


func join(player_name: String):
	# -- the rest of initialization in NetManager is through a callback on
	# -- connection signal
	NetManager.local_player_name = player_name
	if active_backend == null:
		await switch_to_backend(backend_type)
	active_backend.join(player_name)


func get_join_text():
	if using_steam():
		return "Searching for Steam Lobby..."
	else:
		return "Connecting to %s..." % active_backend.ip


func using_steam() -> bool:
	return backend_type == BackendType.STEAM


func using_enet() -> bool:
	return !using_steam()
