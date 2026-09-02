# Represents the current offer for one player on one wager.
# Odds and revision can change as new offers are generated during a race.
class_name WagerOffer
extends RefCounted

var wager_id: StringName
var contestant_peer_id: int
var odds_multiplier: float
var revision: int


func _init(
	p_wager_id: StringName = &"",
	p_contestant_peer_id: int = 0,
	p_odds_multiplier: float = 1.0,
	p_revision: int = 0
) -> void:
	
	wager_id = p_wager_id
	contestant_peer_id = p_contestant_peer_id
	odds_multiplier = p_odds_multiplier
	revision = p_revision
