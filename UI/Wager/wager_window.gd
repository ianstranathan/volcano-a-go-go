# Top-level controller for the wager UI flow.
# It coordinates screens and converts the player's final UI choices into a WagerRequest for WagerManager.
class_name WagerWindow
extends Control

@onready var wager_selection_screen: WagerSelectionScreen = %WagerSelectionScreen
@onready var contestant_selection_screen: ContestantSelectionScreen = %ContestantSelectionScreen
@onready var back_button: Button = %BackButton
@onready var confirm_button: Button = %ConfirmButton

var wager_manager: WagerManager
var player_data_dict: Dictionary = {}

var selected_wager: WagerData
var selected_offer: WagerOffer


func _ready() -> void:
	wager_selection_screen.wager_selected.connect(_on_wager_selected)
	contestant_selection_screen.selection_changed.connect(_on_contestant_selection_changed)

	back_button.pressed.connect(_on_back_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	Events.wager_window_requested.connect(open)
	
	hide()
	
func open() -> void:
	assert(wager_manager != null)

	selected_wager = null
	selected_offer = null

	var available_wagers: Array[WagerData] = wager_manager.get_available_wagers()

	wager_selection_screen.setup(available_wagers)
	_show_wager_selection()

	show()


func close() -> void:
	hide()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


# Game injects session player data so the UI does not need to search the scene tree for contestants.
func set_player_data(data: Dictionary) -> void:
	player_data_dict = data


func set_wager_manager(manager: WagerManager) -> void:
	wager_manager = manager


func _show_wager_selection() -> void:
	wager_selection_screen.show()
	contestant_selection_screen.hide()

	confirm_button.disabled = true


# Retrieves the latest offers from WagerManager each time a wager type is selected.
func _show_contestant_selection() -> void:
	wager_selection_screen.hide()
	contestant_selection_screen.show()

	confirm_button.disabled = true

	var offers: Array[WagerOffer] = wager_manager.get_offers_for_wager(
		selected_wager.id
	)

	contestant_selection_screen.setup(
		selected_wager,
		player_data_dict,
		offers
	)


func _on_wager_selected(wager: WagerData) -> void:
	selected_wager = wager
	selected_offer = null

	_show_contestant_selection()


func _on_contestant_selection_changed(offer: WagerOffer) -> void:
	selected_offer = offer
	confirm_button.disabled = false


# With only two screens, Back can use visibility to determine where to go.
# Replace this with explicit screen state/history if the window grows beyond this flow.
func _on_back_pressed() -> void:
	if contestant_selection_screen.visible:
		selected_offer = null
		_show_wager_selection()
	else:
		close()


# Packages only the player's choices into a request.
# WagerManager will eventually validate the request and determine the authoritative accepted odds.
func _on_confirm_pressed() -> void:
	if selected_wager == null or selected_offer == null:
		return

	assert(wager_manager != null)

	var amount: int = contestant_selection_screen.get_wager_amount()

	var request := WagerRequest.new(
		selected_wager.id,
		selected_offer.contestant_peer_id,
		amount
	)

	wager_manager.request_wager(request)
	close() # Move this to after a wager is accepted once we get that far
