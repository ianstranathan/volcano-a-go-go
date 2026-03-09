extends Node

signal connection_failed

var current_lobby_id # -- Steam.createLobby returns a lobby_id
var LOBBY_KEY = "Volcano-Go-Go"

var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
const APP_ID = "480" # SpaceWar

const PORT := 8910
const MAX_CLIENTS := 3 # Host + 3 clients = 4 total players


func close_connection():
	if current_lobby_id > 0:
		Steam.leaveLobby(current_lobby_id)
		current_lobby_id = 0
	
	# -- close the actual Peer (if it exists)
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()


func _ready() -> void:
	# Initialize Steam
	OS.set_environment("SteamAppId", APP_ID)
	var init = Steam.steamInitEx()
	print("Steam Init: ", init)
	
	# Steam Specific Signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)


func _on_lobby_created(connect_result: int, lobby_id: int) -> void:
	if connect_result == 1:
		current_lobby_id = lobby_id
		var err = peer.create_host(0)
		if err == OK:
			multiplayer.multiplayer_peer = peer
			# Tag the lobby so your friends can find it
			Steam.setLobbyData(lobby_id, "my_game_key", LOBBY_KEY)
			Steam.setLobbyData(lobby_id, "host_id", str(Steam.getSteamID()))
			#player_info_updated.emit(1, player_data[1][KEY_NAME], 0)
			print("Steam Host Started.")
		else:
			connection_failed.emit()


var _pending_player_name: String = ""


func join(player_name: String) -> void:
	_pending_player_name = player_name
	Steam.addRequestLobbyListStringFilter("my_game_key", LOBBY_KEY, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()


func _on_lobby_match_list(lobbies: Array) -> void:
	if lobbies.size() > 0:
		var host_id = Steam.getLobbyData(lobbies[0], "host_id").to_int()
		var err = peer.create_client(host_id, 0)
		if err != OK: connection_failed.emit()
		multiplayer.multiplayer_peer = peer
	else:
		connection_failed.emit()


func _process(_delta: float) -> void:
	Steam.run_callbacks()

func host() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_CLIENTS + 1)
