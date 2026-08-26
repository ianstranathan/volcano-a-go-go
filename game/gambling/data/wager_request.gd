# Carries the player's intent to place a wager.
# Only player-selected values belong here; the manager will determine authoritative odds and bettor identity.
class_name WagerRequest
extends RefCounted

var wager_id: StringName
var contestant_peer_id: int
var amount: int


func _init(p_wager_id: StringName = &"",p_contestant_peer_id: int = 0,p_amount: int = 0) -> void:
	wager_id = p_wager_id
	contestant_peer_id = p_contestant_peer_id
	amount = p_amount
