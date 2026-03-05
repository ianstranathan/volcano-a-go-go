extends Node

""" 
global signal bus to cut around making a bunch of
percolating signals
"""


# -- world items connect to this signal in its _ready
signal item_picked_up( world_id: int)

# -- world effects connects to this in its _ready
signal world_effect( player_id: int, effect_type: Effects.EffectNames, pos: Vector2, flip:bool)
