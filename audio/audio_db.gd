extends Node

# ------------------------------------------------------------------------------
# Central lookup for audio IDs and their default playback settings.
# ------------------------------------------------------------------------------

enum PlaybackMode {
	RESTART,
	OVERLAP,
	IGNORE_IF_PLAYING
}

enum LocalSoundId {
	UI_CLICK,
	HOTBAR_TICK,
}

enum WorldSoundId{
	HOOKSHOT_FIRE,
	JUMP,
	JUMP_LAND,

}
enum MusicTrackId {

	GAMEPLAY,
}

# ------------------------------------------------------------------------------
# Local one-shot sounds
# ------------------------------------------------------------------------------

var local_sounds: Dictionary = {
	 LocalSoundId.UI_CLICK: {
	 	"stream": preload("res://audio/ui/ui_click.ogg"),
	 	"bus": &"UI",
	 	"playback_mode": PlaybackMode.RESTART,
	 	"default_volume_db": 0.0,
	 	"default_pitch_scale": 1.0,
	 },
	
	LocalSoundId.HOTBAR_TICK: {
	 	"stream": preload("res://audio/ui/hotbar_tick.ogg"),
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
		"stream": preload("res://audio/clips/Jump.wav"),
		"bus": &"Effects",
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
		"max_distance": 800.0,
		"attenuation": 1.0,
		"panning_strength": 1.0,
	},
		WorldSoundId.JUMP_LAND: {
		"stream": preload("res://audio/clips/Jump_Land.wav"),
		"bus": &"Effects",
		"default_volume_db": 0.0,
		"default_pitch_scale": 1.0,
		"max_distance": 800.0,
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
	},
}
