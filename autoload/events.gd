extends Node

""" 
global signal bus to cut around making a bunch of percolating signals

NOTE, if adding to this, be sure it's a on off thing / event
I think there's a lot of pointer indirection in this pattern, so if it's
a hot loop or something that happens a bunch, try to avoid
"""

# -- camera connects to this in its _ready
signal shake_cam(shake: ShakeInstance)

# -- PickupItems connects to this signal in its _ready
signal item_picked_up( world_id: int)

# -- SpawnedItemns connects to this in its _ready
#signal item_spawned( item_key: ItemsDb.ItemNames, fn:Callable)

# --  WorldEffects connects to this signal in its _ready
#signal world_effect( player_id: int, effect_type: Effects.EffectNames, pos: Vector2, flip:bool)
signal world_effect(player_id: int, params: EffectParameters)

# -- HotBar connects to this in its _ready
signal inventory_changed(item_db_enums: Array,
						selected_index: int, 
						special_item)
# -- Block Player Input
signal input_blocked(blocked: bool)

# -- AudioManager connects to these signals in its _ready
signal play_local_sound(sound_id: int, volume_db_offset: float, pitch_scale_mult: float)
signal play_music(track_id: int, volume_db_offset: float, pitch_scale_mult: float)
signal stop_music()
signal play_world_sound(sound_id: int, world_position: Vector2, volume_db_offset: float, pitch_scale_mult: float, world_overrides: Dictionary)
signal start_world_loop(loop_key: StringName, loop_id: int, source: Node2D, volume_db_offset: float, pitch_scale_mult: float, world_overrides: Dictionary)
signal stop_world_loop(loop_key: StringName)
