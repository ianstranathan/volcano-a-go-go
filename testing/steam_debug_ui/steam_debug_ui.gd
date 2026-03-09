extends CanvasLayer

# Using @onready with find_child makes it harder to break if you move nodes
@onready var status_label = find_child("StatusLabel")
@onready var host_btn = find_child("HostButton")
@onready var join_btn = find_child("JoinButton")

func _ready():
	# Force the text so we know the script is talking to the nodes
	host_btn.text = "HOST STEAM GAME"
	join_btn.text = "SEARCH FOR LOBBIES"
	if not status_label:
		printerr("CRITICAL: UI Nodes not found! Check your node names in the scene tree.")
		return
	
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)

func _process(_delta):
	# We update every frame here for debugging
	_update_ui()

func _update_ui():
	# 1. Check if Steam is actually initialized before calling any functions
	if not Steam.isSteamRunning():
		status_label.text = "Waiting for Steam..."
		status_label.modulate = Color.YELLOW
		return

	# 2. Get your name safely
	var my_name = Steam.getPersonaName()
	if my_name == "":
		status_label.text = "Loading User..."
		return

	var net_id = multiplayer.get_unique_id()
	
	# 3. Check if the peer is active
	var peer_status = "Disconnected"
	if multiplayer.multiplayer_peer is SteamMultiplayerPeer:
		peer_status = "Steam Relay Active"
	
	status_label.text = "STEAM: %s\nNET ID: %d\nSTATUS: %s" % [my_name, net_id, peer_status]
	status_label.modulate = Color.GREEN

func _on_host_pressed():
	print("UI: Host Button Clicked")
	SteamManager.host_game()

func _on_join_pressed():
	print("UI: Join Button Clicked")
	SteamManager.search_for_games()
