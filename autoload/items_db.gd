@tool
extends Node

# ItemDatabase.gd (Autoload)
enum ItemNames{
	GRAPPLING_HOOK,
	PARACHUTE,
	ROPE
}

var items = {
	ItemNames.GRAPPLING_HOOK: preload("res://items/grappling_hook/grappling_hook.tscn"),
	ItemNames.PARACHUTE:      preload("res://items/parachute/parachute.tscn"),
	ItemNames.ROPE:           preload("res://items/rope_ladder/rope_ladder_spawner.tscn"),
}

var item_pickup_textures = {
	ItemNames.GRAPPLING_HOOK: preload("res://assets/grapple.svg"),
	ItemNames.PARACHUTE:      preload("res://assets/parachute.svg"),
	ItemNames.ROPE:           preload("res://assets/rope-coil.svg"),
}

func get_texture(item_key: ItemNames) -> Texture2D:
	assert(item_key in items)
	return item_pickup_textures[ item_key ]
#ItemsDb.get_texture(item_lookup)

func get_item_from_lookup( item_key: ItemNames ) -> PackedScene:
	assert(item_key in items)
	return items[item_key]
