extends Node

""" 
global signal bus to cut around making a bunch of
percolating signals
"""

# -- PickupItems connects to this signal in its _ready
signal item_picked_up( world_id: int)

# -- SpawnedItemns connects to this in its _ready
signal item_spawned( item_key: ItemsDb.ItemNames, fn:Callable)

# --  WorldEffects connects to this signal in its _ready
signal world_effect( player_id: int, effect_type: Effects.EffectNames, pos: Vector2, flip:bool)
