extends Control

@onready var hotbar_ui: HotbarUi = $HudMargin/HudLayout/BottomArea/BottomCenter/CenterContainer/HotbarUi

func _ready() -> void:
	var players_container = get_node("/root/Game/PlayersContainer")
	#timing issues, does this warrant being added to events?
	players_container.child_entered_tree.connect(_on_player_added)
	
	#dont know if a player will ever be ready when this runs
	for player in players_container.get_children():
		get_local_player(player)
		
func _on_player_added(player: Node) -> void:
	get_local_player(player)
	
func get_local_player(player: Node) -> void:		
	if player.get_multiplayer_authority() == multiplayer.get_unique_id():
		var item_manager: ItemManager = player.get_node("ItemManager")
		if not item_manager.inventory_changed.is_connected(_on_inventory_changed):
			item_manager.inventory_changed.connect(_on_inventory_changed)

			_on_inventory_changed(
				item_manager.inventory_items, 
				item_manager.selected_slot_index, 
				item_manager.special_item)
			return
	
func _on_inventory_changed(standard_items: Array, selected_index: int, special_item) -> void:
	hotbar_ui.set_inventory_display(standard_items, selected_index, special_item)
