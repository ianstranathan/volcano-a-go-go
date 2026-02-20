extends Node

""" 
global signal bus to cut around making a bunch of
percolating signals
"""


# -- world items connect to this signal in its _ready
signal item_picked_up( world_id: int)
