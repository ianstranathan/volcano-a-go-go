@tool
extends Node

# ItemDatabase.gd (Autoload)

enum ItemNames{
	#GRAPPLING_HOOK,
	HOOKSHOT,
	PARACHUTE,
	ROPE,
	ROPE_LADDER
}


var items = {
	#ItemNames.GRAPPLING_HOOK: preload("res://items/grappling_hook/grappling_hook.tscn"),
	ItemNames.HOOKSHOT:       preload("res://items/hookshot/hookshot.tscn"),
	ItemNames.PARACHUTE:      preload("res://items/parachute/parachute.tscn"),
	ItemNames.ROPE:           preload("res://items/rope_ladder/rope_ladder_spawner.tscn"),
	ItemNames.ROPE_LADDER:    preload("res://items/rope_ladder/rope_ladder.tscn")
}


var item_pickup_textures = {
	ItemNames.HOOKSHOT:       preload("res://assets/hookshot.svg"),
	ItemNames.PARACHUTE:      preload("res://assets/parachute.svg"),
	ItemNames.ROPE:           preload("res://assets/rope-coil.svg"),
}


func get_texture(item_key: ItemNames) -> Texture2D:
	#print("in get_tex: ", item_key)
	assert(item_key in items)
	return item_pickup_textures[ item_key ]


func get_item_from_lookup( item_key: ItemNames ) -> PackedScene:
	assert(item_key in items)
	return items[item_key]
