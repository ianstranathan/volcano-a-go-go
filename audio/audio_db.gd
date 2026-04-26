extends Node

# ------------------------------------------------------------------------------
# AudioDb
# Central lookup for all audio ids and their default playback settings.
#
# Categories:
# - local_sounds: client-only UI and menu sounds
# - world_sounds: one-shot 2D sounds played in world space
# - world_loops: tracked 2D loop sounds started and stopped by key
# - music_tracks: non-spatial background music
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ADJUSTMENT RULES
# ------------------------------------------------------------------------------
# volume_db_offset is added to the sound's default_volume_db.
# pitch_scale_mult is multiplied by the sound's default_pitch_scale.
#
# These are adjustments, not direct overrides.
#
# Example:
# default_volume_db = -2.0
# default_pitch_scale = 0.95
# call uses volume_db_offset = -3.0 and pitch_scale_mult = 1.05
# final volume_db = -5.0
# final pitch_scale = 0.9975

# ------------------------------------------------------------------------------
# CALL TEMPLATES
# ------------------------------------------------------------------------------
# Local one-shot
# Events.emit_signal("play_local_sound", AudioDb.LocalSoundId.UI_CLICK, 0.0, 1.0)
#
# Local one-shot with pitch variation
# Events.emit_signal(
# 	"play_local_sound",
# 	AudioDb.LocalSoundId.HOTBAR_TICK,
# 	0.0,
# 	randf_range(0.98, 1.02)
# )
#
# Music
# Events.emit_signal("play_music", AudioDb.MusicTrackId.GAMEPLAY, 0.0, 1.0)
# Events.emit_signal("stop_music")
#
# World one-shot
# Usually emit from the multiplayer authority side and avoid replay paths.
# if is_multiplayer_authority() and not player_ref.is_replaying:
# 	Events.emit_signal(
# 		"play_world_sound",
# 		AudioDb.WorldSoundId.HOOKSHOT_FIRE,
# 		global_position,
# 		0.0,
# 		1.0,
# 		{
#		Optional Overrides
# 		"max_distance": 900.0,
# 		"attenuation": 1.2,
# 		"panning_strength": 1.0,
#		}
# 	)
#
#
# World loop start
# if is_multiplayer_authority() and not player_ref.is_replaying:
# Events.emit_signal(
# 	"start_world_loop",
# 	loop_key,
# 	AudioDb.WorldLoopId.PARACHUTE_DESCEND,
# 	self,
# 	0.0,
# 	1.0,
# 	{
#	Optional Overrides
# 	"max_distance": 900.0,
# 	"attenuation": 1.2,
# 	"panning_strength": 1.0,
#	}
# )
#
# World loop stop
# Events.emit_signal("stop_world_loop", loop_key)
#


enum PlaybackMode {
	RESTART,
	OVERLAP,
	IGNORE_IF_PLAYING
}

enum LocalSoundId {
	UI_CLICK,
	HOTBAR_TICK,
}

enum WorldSoundId {
	HOOKSHOT_FIRE,
	JUMP,
	JUMP_LAND,
	PARACHUTE_OPEN,
	ITEM_PICKUP,
}

# Keep looping world sounds separate from one-shots.
enum WorldLoopId {
	PARACHUTE_DESCEND,
}

enum MusicTrackId {
	GAMEPLAY,
}

# ------------------------------------------------------------------------------
# Local one-shot sounds
# ------------------------------------------------------------------------------
var local_sounds: Dictionary = {
	LocalSoundId.UI_CLICK: {
		"stream": preload("res://audio/ui/ui_click.mp3"),
		"bus": &"UI",
		"playback_mode": PlaybackMode.RESTART,
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
	},
	LocalSoundId.HOTBAR_TICK: {
		"stream": preload("res://audio/ui/hotbar_tick.mp3"),
		"bus": &"UI",
		"playback_mode": PlaybackMode.RESTART,
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
	},
}

# ------------------------------------------------------------------------------
# World one-shot sounds
# ------------------------------------------------------------------------------
var world_sounds: Dictionary = {
	WorldSoundId.HOOKSHOT_FIRE: {
		"stream": preload("res://audio/clips/HookShot_Fire.mp3"),
		"bus": &"Effects",
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
		"max_distance": 1200.0,
		"attenuation": 1.0,
		"panning_strength": 1.0,
	},
	WorldSoundId.JUMP: {
		"stream": preload("res://audio/clips/Jump.mp3"),
		"bus": &"Effects",
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
		"max_distance": 800.0,
		"attenuation": 1.0,
		"panning_strength": 1.0,
	},
	WorldSoundId.JUMP_LAND: {
		"stream": preload("res://audio/clips/Jump_Land.mp3"),
		"bus": &"Effects",
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
		"max_distance": 800.0,
		"attenuation": 1.0,
		"panning_strength": 1.0,
	},
	WorldSoundId.PARACHUTE_OPEN: {
		"stream": preload("res://audio/clips/Parachute_Open.mp3"),
		"bus": &"Effects",
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
		"max_distance": 800.0,
		"attenuation": 1.0,
		"panning_strength": 1.0,
	},
	WorldSoundId.ITEM_PICKUP: {
		"stream": preload("res://audio/clips/Pick_Up.mp3"),
		"bus": &"Effects",
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
		"max_distance": 800.0,
		"attenuation": 1.0,
		"panning_strength": 1.0,
	},
}

# ------------------------------------------------------------------------------
# World looping sounds
# ------------------------------------------------------------------------------
var world_loops: Dictionary = {
	WorldLoopId.PARACHUTE_DESCEND: {
		"stream": preload("res://audio/clips/Parachute_descend.mp3"),
		"bus": &"Effects",
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
		"max_distance": 1200.0,
		"attenuation": 1.0,
		"panning_strength": 1.0,
	},
}

# ------------------------------------------------------------------------------
# Music tracks
# ------------------------------------------------------------------------------
var music_tracks: Dictionary = {
	MusicTrackId.GAMEPLAY: {
		"stream": preload("res://audio/music/Dust of the Dunes.mp3"),
		"bus": &"Music",
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
	},
}
