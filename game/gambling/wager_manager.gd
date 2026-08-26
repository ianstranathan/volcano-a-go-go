# Owns wager definitions and the current runtime offers for this match.
class_name WagerManager
extends Node

var available_wagers: Array[WagerData] = []
var current_offers: Dictionary = {}
var player_data_dict: Dictionary = {}
var offer_revisions: Dictionary = {}


func _ready() -> void:
	_create_wager_definitions()


# Wager definitions are hard-coded for now. These could become Resources later.
func _create_wager_definitions() -> void:
	available_wagers = [
		WagerData.new(
			&"race_winner",
			"Race Winner",
			"Wager on who reaches the top first."
		),
		WagerData.new(
			&"first_eliminated",
			"First Eliminated",
			"Wager on who is eliminated first."
		),
		WagerData.new(
			&"checkpoint_leader",
			"Highest at Checkpoint",
			"Wager on who is leading at the checkpoint."
		),
		WagerData.new(
			&"last_survivor",
			"Last Survivor",
			"Wager on who remains at the end."
		)
	]


func get_available_wagers() -> Array[WagerData]:
	return available_wagers


# This is the handoff point from UI into gameplay.
# Validation, networking, currency handling, and ActiveWager creation will be added here later.
func request_wager(request: WagerRequest) -> void:
	print("--- WAGER REQUEST ---")
	print("Wager ID: ", request.wager_id)
	print("Contestant Peer ID: ", request.contestant_peer_id)
	print("Amount: ", request.amount)
	print("---------------------")


func get_offers_for_wager(wager_id: StringName) -> Array[WagerOffer]:
	var offers: Array[WagerOffer] = []

	if not current_offers.has(wager_id):
		return offers

	for offer in current_offers[wager_id]:
		offers.append(offer)

	return offers


# Keeps offer replacement behind one method so future offer updates have a single entry point.
func set_offers_for_wager(wager_id: StringName,offers: Array[WagerOffer]) -> void:
	current_offers[wager_id] = offers

# Game injects the current session player registry after players have been spawned.
func set_player_data(data: Dictionary) -> void:
	player_data_dict = data
	_rebuild_all_offers()


func _rebuild_all_offers() -> void:
	for wager in available_wagers:
		_rebuild_offers_for_wager(wager.id)


# Builds one offer per player for the requested wager.
# Neutral odds are used until player statistics are implemented.
func _rebuild_offers_for_wager(wager_id: StringName) -> void:
	var player_ids := player_data_dict.keys()
	player_ids.sort()

	if player_ids.is_empty():
		set_offers_for_wager(wager_id, [])
		return

	var revision: int = _next_offer_revision(wager_id)
	var odds_multiplier: float = _calculate_neutral_odds(player_ids.size())
	var offers: Array[WagerOffer] = []

	for player_id in player_ids:
		var offer := WagerOffer.new(
			wager_id,
			int(player_id),
			odds_multiplier,
			revision
		)

		offers.append(offer)

	set_offers_for_wager(wager_id, offers)


# Each rebuild gets a new revision so a future request can identify which offer the player saw.
func _next_offer_revision(wager_id: StringName) -> int:
	var revision: int = int(offer_revisions.get(wager_id, 0)) + 1
	offer_revisions[wager_id] = revision

	return revision


# odds when we dont know anything about the player more players = worse odds
func _calculate_neutral_odds(contestant_count: int) -> float:
	if contestant_count <= 0:
		return 1.0

	return float(contestant_count)
