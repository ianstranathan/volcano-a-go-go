class_name ContestantCard
extends Button

signal selected(player_data: PlayerData)

@onready var player_icon = %PlayerIcon
@onready var player_name: Label = %PlayerName
@onready var odds_label: Label = %OddsLabel

var player_data: PlayerData
var odds: float


func _ready() -> void:
	toggle_mode = true
	pressed.connect(_on_pressed)

	player_icon.set_placement_visible(false)


func setup(data: PlayerData, player_odds: float) -> void:
	player_data = data
	odds = player_odds

	player_name.text = player_data.display_name

	player_icon.change_turban_color(player_data.turban_color)
	player_icon.change_icon_skin_tone(player_data.skin_tone)

	odds_label.text = "%.1fx" % odds


func _on_pressed() -> void:
	selected.emit(player_data)
