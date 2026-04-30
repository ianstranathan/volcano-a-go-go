extends Node
"""
So much fiddly BS

steam id doesn't map for peer id 1

steam compresses its images, strips out a row of pixels or soemthing
(was returning a 64x63....)
which forces byte arithmetic to make an avatar
"""

signal connection_failed
signal avatar_ready(peer_id, texture)
#signal avatar_ready(steam_id, texture)

var current_lobby_id # -- Steam.createLobby returns a lobby_id
var LOBBY_KEY = "Volcano-Go-Go"

var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
# steam multiplayer api: 
# get_steam_id_for_peer_id
# get_peer_id_for_steam_id


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
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	
	# Docs:Emits signal in response to function Steam.getLargeFriendAvatar(), 
	# Steam.getMediumFriendAvatar(), or Steam.getSmallFriendAvatar().
	Steam.avatar_loaded.connect(on_avatar_loaded)


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


var avatar_img_cache:       Dictionary = {} # -- steam id to img
var avatar_request_handles: Dictionary = {} # -- request ptr to steam id 

func request_avatar(peer_id: int) -> void:
	var _steam_id = Steam.getSteamID() if peer_id == multiplayer.get_unique_id() else peer.get_steam_id_for_peer_id(peer_id)

	if _steam_id == 0:
		_retry_avatar_request(peer_id)
		return

	if avatar_img_cache.has(_steam_id):
		avatar_ready.emit(peer_id, avatar_img_cache[_steam_id])
		return

	var handle = Steam.getMediumFriendAvatar(_steam_id)
	if handle > 0: 
		var size = Steam.getImageSize(handle)
		var data = Steam.getImageRGBA(handle)
		if data["success"]:
			_create_texture_from_raw_data(_steam_id, size["width"], data["buffer"])
	else:
		avatar_request_handles[handle] = peer_id


func on_avatar_loaded(handle_id: int, width: int, buffer: Array) -> void:
	if avatar_request_handles.has(handle_id):
		var _peer_id = avatar_request_handles[handle_id]
		var tex = _create_texture_from_raw_data(0, width, buffer) # ID 0 just for cache
		avatar_ready.emit(_peer_id, tex)
		avatar_request_handles.erase(handle_id)


func _create_texture_from_raw_data(_steam_id: int, width: int, buffer: Array) -> ImageTexture:
	if buffer.is_empty(): 
		return null

	var byte_array = PackedByteArray(buffer)
	var total_bytes = byte_array.size()
	var height: int = total_bytes / (width * 4)
	
	var image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, byte_array)
	
	if image == null:
		print("Failed to create image from Steam data")
		return null
		
	var texture = ImageTexture.create_from_image(image)
	avatar_img_cache[_steam_id] = texture
	
	var p_id: int = 0
	if _steam_id == Steam.getSteamID():
		p_id = multiplayer.get_unique_id()
	else:
		p_id = peer.get_peer_id_for_steam_id(_steam_id)
	
	if p_id != 0:
		avatar_ready.emit(p_id, texture)
	else:
		print("Steam ID mapped to Peer 0, deferring signal for: ", _steam_id)
		
	return texture
#func request_avatar(peer_id: int) -> void:
	## Steam.getSteamID() docs:
	## Gets the Steam ID (ID64) of the account currently logged into the Steam client. 
	## This is commonly called the 'current user', or 'local user'.
	#var _steam_id = Steam.getSteamID() if peer_id == multiplayer.get_unique_id() else peer.get_steam_id_for_peer_id(peer_id)
#
	## -- short circuit if we've already made the texture in the avatar callback
	#if avatar_img_cache.has(_steam_id):
		#avatar_ready.emit(peer_id, avatar_img_cache[_steam_id])
		#return
#
	## -- this is just a safety wait, keeps trying until steam's been
	## -- fully intialized
	## -- bad design though, should wait until steam is set up before ever
	## -- trying this (see NetManager)
	#
	#if _steam_id != 0:
		#if _avatar_retry_counts.has(peer_id):
			#_avatar_retry_counts.erase(peer_id)
	#else:
		#_retry_avatar_request(peer_id)
		#return
		#
	##if _steam_id == 0:
		##_retry_avatar_request(peer_id)
		##return
#
	## -- Steam.getMediumFriendAvatar returns immediately 
	## -- or triggers avatar_loaded later
	#var handle = Steam.getMediumFriendAvatar(_steam_id)
	#if handle > 0: 
		#_create_texture_from_raw_data(_steam_id,
									  #Steam.getImageSize(handle)["width"],
									  #Steam.getImageRGBA(handle)["buffer"])
	#else:
		## -- get an key to have for the callback in on_avatar_loaded
		#avatar_request_handles[handle] = _steam_id
#
#
#func on_avatar_loaded(handle_id: int, width: int, buffer: Array) -> void:
	#if avatar_request_handles.has(handle_id):
		#var _steam_id = avatar_request_handles[handle_id]
		#_create_texture_from_raw_data(_steam_id, width, buffer)
		#avatar_request_handles.erase(handle_id)


#func _create_texture_from_raw_data(_steam_id: int, width: int, buffer: Array) -> void:
	#if buffer.is_empty(): 
		#return
#
	#var byte_array = PackedByteArray(buffer)
	#var total_bytes = byte_array.size()
	#var height: int = total_bytes / (width * 4)
	#var image = Image.create_from_data( width, 
										#height, 
										#false, 
										#Image.FORMAT_RGBA8, 
										#byte_array)
	#if image == null:
		#print("Failed to create image from Steam data")
		#return
	#var texture = ImageTexture.create_from_image(image)
	#avatar_img_cache[_steam_id] = texture
	#
	#var p_id = multiplayer.get_unique_id() if _steam_id == Steam.getSteamID() else peer.get_peer_id_for_steam_id(_steam_id)
	#avatar_ready.emit(p_id, texture)

#var _pending_avatar_retries: Dictionary = {}
#func _retry_avatar_request(peer_id: int) -> void:
	#if _pending_avatar_retries.has(peer_id):
		#return
	#_pending_avatar_retries[peer_id] = true
	#call_deferred("_retry_avatar_request_deferred", peer_id)
#
#
#func _retry_avatar_request_deferred(peer_id: int) -> void:
	#await get_tree().create_timer(0.2).timeout
	#_pending_avatar_retries.erase(peer_id)
	#request_avatar(peer_id)
var _avatar_retry_counts: Dictionary = {}

func _retry_avatar_request(peer_id: int) -> void:
	# 1. Initialize the counter if this is the first attempt
	if not _avatar_retry_counts.has(peer_id):
		_avatar_retry_counts[peer_id] = 0
	
	# 2. Increment and check for a "Hard Stop"
	_avatar_retry_counts[peer_id] += 1
	
	if _avatar_retry_counts[peer_id] > 25: # Bail after ~5 seconds
		print("Avatar Request: Max retries reached for peer ", peer_id)
		_avatar_retry_counts.erase(peer_id)
		# OPTIONAL: emit a default "No Avatar" texture here
		return

	# 3. Use call_deferred to jump out of the current call stack
	call_deferred("_retry_avatar_request_deferred", peer_id)


func _retry_avatar_request_deferred(peer_id: int) -> void:
	await get_tree().create_timer(0.2).timeout
	
	# 4. Peer Validation: Stop if they are gone
	if not multiplayer.get_peers().has(peer_id) and peer_id != multiplayer.get_unique_id():
		_avatar_retry_counts.erase(peer_id)
		return

	# 5. Call request_avatar again
	# We DON'T erase the retry count here; request_avatar will call 
	# _retry_avatar_request again if it still fails, incrementing the count.
	request_avatar(peer_id)

	# 6. Success Cleanup
	# In your request_avatar() function, if it SUCCEEDS, 
	# you MUST call _avatar_retry_counts.erase(peer_id)
