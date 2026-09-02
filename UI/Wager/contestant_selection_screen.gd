# Displays the current contestants for a selected wager and manages the local wager amount preview.
# It consumes WagerOffers supplied by WagerManager.
class_name ContestantSelectionScreen
extends MarginContainer

signal selection_changed(offer: WagerOffer)

@export var contestant_card_scene: PackedScene

@onready var wager_title_label: Label = %WagerTitleLabel
@onready var contestant_grid: GridContainer = %ContestantGrid
@onready var selected_name_label: Label = %SelectedNameLabel
@onready var selected_odds_label: Label = %SelectedOddsLabel
@onready var decrease_button: Button = %DecreaseButton
@onready var increase_button: Button = %IncreaseButton
@onready var amount_value_label: Label = %AmountValueLabel
@onready var payout_value_label: Label = %PayoutValueLabel

const MIN_WAGER := 25
const MAX_WAGER := 1000
const WAGER_STEP := 25
const DEFAULT_WAGER := 100

var selected_card: ContestantCard
var contestant_button_group := ButtonGroup.new()
var wager_amount: int = DEFAULT_WAGER


func _ready() -> void:
	decrease_button.pressed.connect(_on_decrease_pressed)
	increase_button.pressed.connect(_on_increase_pressed)


func setup(wager: WagerData,player_data_dict: Dictionary,offers: Array[WagerOffer]) -> void:
	var offers_by_peer_id: Dictionary = {}

	for offer in offers:
		offers_by_peer_id[offer.contestant_peer_id] = offer

	wager_title_label.text = wager.display_name
	selected_card = null
	wager_amount = DEFAULT_WAGER

	_clear_cards()
	_update_details()
	_update_wager_display()

	var player_ids := player_data_dict.keys()
	player_ids.sort()

	contestant_grid.columns = max(1, offers_by_peer_id.size())

	for player_id in player_ids:
		if not offers_by_peer_id.has(player_id):
			continue

		var player_data: PlayerData = player_data_dict[player_id]
		var offer: WagerOffer = offers_by_peer_id[player_id]

		var card: ContestantCard = contestant_card_scene.instantiate()
		contestant_grid.add_child(card)

		card.setup(player_data, offer)
		card.button_group = contestant_button_group
		card.selected.connect(_on_contestant_selected.bind(card))


func _clear_cards() -> void:
	for child in contestant_grid.get_children():
		contestant_grid.remove_child(child)
		child.queue_free()


func _on_contestant_selected(card: ContestantCard) -> void:
	selected_card = card

	_update_details()
	_update_wager_display()

	selection_changed.emit(card.wager_offer)


func _update_details() -> void:
	if selected_card == null:
		selected_name_label.text = "Select a contestant"
		selected_odds_label.text = ""
		return

	selected_name_label.text = selected_card.player_data.display_name
	selected_odds_label.text = "Current Odds: %.1fx" % selected_card.wager_offer.odds_multiplier


func _on_decrease_pressed() -> void:
	wager_amount = max(MIN_WAGER, wager_amount - WAGER_STEP)
	_update_wager_display()


func _on_increase_pressed() -> void:
	wager_amount = min(MAX_WAGER, wager_amount + WAGER_STEP)
	_update_wager_display()


# Payout is only a client-side preview. The accepted wager will eventually use host-authoritative odds.
func _update_wager_display() -> void:
	amount_value_label.text = str(wager_amount)

	if selected_card == null:
		payout_value_label.text = "---"
		return

	var odds: float = selected_card.wager_offer.odds_multiplier
	var payout: int = int(round(float(wager_amount) * odds))

	payout_value_label.text = str(payout)


func get_wager_amount() -> int:
	return wager_amount
