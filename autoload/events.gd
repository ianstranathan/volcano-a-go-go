extends Node

""" 
global signal bus to cut around making a bunch of percolating signals

NOTE, if adding to this, be sure it's a on off thing / event
I think there's a lot of pointer indirection in this pattern, so if it's
a hot loop or something that happens a bunch, try to avoid
"""

# -- PickupItems connects to this signal in its _ready
signal item_picked_up( world_id: int)

# -- SpawnedItemns connects to this in its _ready
signal item_spawned( item_key: ItemsDb.ItemNames, fn:Callable)

# --  WorldEffects connects to this signal in its _ready
signal world_effect( player_id: int, effect_type: Effects.EffectNames, pos: Vector2, flip:bool)

# -- HotBar connects to this in its _ready
signal inventory_changed(item_db_enums: Array,
						selected_index: int, 
						special_item)
