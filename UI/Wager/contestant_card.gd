# Displays one contestant and the current WagerOffer associated with that player.
class_name ContestantCard
extends Button

signal selected

@onready var player_icon = %PlayerIcon
@onready var player_name: Label = %PlayerName
@onready var odds_label: Label = %OddsLabel

var player_data: PlayerData
var wager_offer: WagerOffer


func _ready() -> void:
	toggle_mode = true
	pressed.connect(_on_pressed)

	player_icon.set_placement_visible(false)


func setup(data: PlayerData, offer: WagerOffer) -> void:
	player_data = data
	wager_offer = offer

	player_name.text = player_data.display_name

	player_icon.change_turban_color(player_data.turban_color)
	player_icon.change_icon_skin_tone(player_data.skin_tone)

	odds_label.text = "%.1fx" % wager_offer.odds_multiplier


func _on_pressed() -> void:
	selected.emit()
