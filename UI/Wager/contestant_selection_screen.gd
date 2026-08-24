class_name ContestantSelectionScreen
extends MarginContainer

signal contestant_selected(player_data: PlayerData)
signal selection_changed(player_data: PlayerData, odds: float)

@export var contestant_card_scene: PackedScene
@onready var contestant_grid: GridContainer = %ContestantGrid
@onready var selected_name_label: Label = %SelectedNameLabel
@onready var selected_odds_label: Label = %SelectedOddsLabel

var selected_player: PlayerData
var selected_card: ContestantCard

var contestant_button_group := ButtonGroup.new()

func setup(player_data_dict: Dictionary) -> void:
	selected_player = null
	selected_card = null
	
	_clear_cards()
	_update_details()
	
	var player_ids := player_data_dict.keys()
	player_ids.sort()

	contestant_grid.columns = max(1, player_ids.size())

	for player_id in player_ids:
		var player_data: PlayerData = player_data_dict[player_id]

		var card: ContestantCard = contestant_card_scene.instantiate()
		contestant_grid.add_child(card)

		var odds := 2.0
		card.setup(player_data, odds)

		card.button_group = contestant_button_group
		card.selected.connect(_on_contestant_selected.bind(card))


func _clear_cards() -> void:
	for child in contestant_grid.get_children():
		contestant_grid.remove_child(child)
		child.queue_free()

func _on_contestant_selected(player_data: PlayerData,card: ContestantCard) -> void:
	selected_player = player_data
	selected_card = card

	card.button_pressed = true
	_update_details()
	selection_changed.emit(player_data, card.odds)
	
func _update_details() -> void:
	if selected_player == null or selected_card == null:
		selected_name_label.text = "Select a contestant"
		selected_odds_label.text = ""
		return

	selected_name_label.text = selected_player.display_name
	selected_odds_label.text = "Current Odds: %.1fx" % selected_card.odds
