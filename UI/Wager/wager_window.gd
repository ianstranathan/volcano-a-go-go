class_name WagerWindow
extends Control

@onready var wager_selection_screen: WagerSelectionScreen = %WagerSelectionScreen
@onready var contestant_selection_screen: ContestantSelectionScreen = %ContestantSelectionScreen
@onready var back_button: Button = %BackButton
@onready var confirm_button: Button = %ConfirmButton

var player_data_dict: Dictionary = {}
var available_wagers: Array[WagerData] = []
var selected_wager: WagerData
var selected_contestant: PlayerData
var selected_odds: float = 0.0

func _ready() -> void:
	create_wagers()
	wager_selection_screen.wager_selected.connect(_on_wager_selected)
	contestant_selection_screen.selection_changed.connect(_on_contestant_selection_changed)

	back_button.pressed.connect(_on_back_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)

	open() 
	
func open() -> void:
	selected_wager = null
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
		
func set_player_data(data: Dictionary) -> void:
	player_data_dict = data

func create_wagers() -> void:
	available_wagers = [
		WagerData.new(
			&"race_winner",
			"Race Winner",
			"Bet on who reaches the top first."
		),
		WagerData.new(
			&"first_eliminated",
			"First Eliminated",
			"Bet on who is eliminated first."
		),
		WagerData.new(
			&"checkpoint_leader",
			"Highest at Checkpoint",
			"Bet on who is leading at the checkpoint."
		),
		WagerData.new(
			&"last_survivor",
			"Last Survivor",
			"Bet on who remains at the end."
		)
	]
	
func _show_wager_selection() -> void:
	wager_selection_screen.show()
	contestant_selection_screen.hide()
	
	confirm_button.disabled = true
	
func _show_contestant_selection() -> void:
	wager_selection_screen.hide()
	contestant_selection_screen.show()
	
	confirm_button.disabled = true
	
	contestant_selection_screen.setup(player_data_dict)
	
func _on_wager_selected(wager: WagerData) -> void:
	selected_wager = wager
	selected_contestant = null
	
	_show_contestant_selection()

func _on_contestant_selection_changed(player_data: PlayerData, odds: float) -> void:
	selected_contestant = player_data
	selected_odds = odds
	confirm_button.disabled = false

#this needs to be updated when we have more screens. TESTING
func _on_back_pressed() -> void:
	if contestant_selection_screen.visible:
		selected_contestant = null
		_show_wager_selection()
	else:
		close()	
		
#this needs to actually send us somewhere when we finish TESTING
func _on_confirm_pressed() -> void:
	if selected_wager == null:
		return

	if selected_contestant == null:
		return

	print(
		"Wager: ",
		selected_wager.display_name,
		" | Contestant: ",
		selected_contestant.display_name
	)
