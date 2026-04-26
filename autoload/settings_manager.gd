extends Node

# ------------------------------------------------------------------------------
# SettingsManager
# Loads and saves user settings to user://settings.cfg.
#
# Current categories:
# - general
# - video
# - audio
# - input
#
# Only audio is implemented for now, but the structure is ready for the rest.
# ------------------------------------------------------------------------------

const SETTINGS_PATH := "user://settings.cfg"

const SECTION_GENERAL := "general"
const SECTION_VIDEO := "video"
const SECTION_AUDIO := "audio"
const SECTION_INPUT := "input"

# In-memory settings cache.
# Keep defaults here so the game can start cleanly even if no config file exists.
var settings := {
	SECTION_GENERAL: {},
	SECTION_VIDEO: {},
	SECTION_AUDIO: {
		"master_volume": 100.0,
		"music_volume": 100.0,
		"effects_volume": 100.0,
		"ui_volume": 100.0,
		"output_device": "Default",
	},
	SECTION_INPUT: {},
}


func _ready() -> void:
	load_settings()


# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)

	# Missing config is normal on first launch. Keep defaults.
	if err != OK:
		apply_all_settings()
		return

	_load_section(config, SECTION_GENERAL)
	_load_section(config, SECTION_VIDEO)
	_load_section(config, SECTION_AUDIO)
	_load_section(config, SECTION_INPUT)

	apply_all_settings()


func save_settings() -> void:
	var config := ConfigFile.new()

	for section in settings.keys():
		var section_values: Dictionary = settings[section]
		for key in section_values.keys():
			config.set_value(section, key, section_values[key])

	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("SettingsManager: Failed to save settings to %s" % SETTINGS_PATH)


func get_setting(section: String, key: String, fallback = null):
	if not settings.has(section):
		return fallback

	var section_values: Dictionary = settings[section]
	return section_values.get(key, fallback)


func set_setting(section: String, key: String, value, save_immediately: bool = true, apply_immediately: bool = true) -> void:
	if not settings.has(section):
		settings[section] = {}

	settings[section][key] = value

	if apply_immediately:
		_apply_setting(section, key, value)

	if save_immediately:
		save_settings()


# ------------------------------------------------------------------------------
# Audio convenience API
# ------------------------------------------------------------------------------

func get_audio_setting(key: String, fallback = null):
	return get_setting(SECTION_AUDIO, key, fallback)


func set_audio_setting(key: String, value, save_immediately: bool = true, apply_immediately: bool = true) -> void:
	set_setting(SECTION_AUDIO, key, value, save_immediately, apply_immediately)


func apply_all_settings() -> void:
	_apply_audio_settings()
	# Future:
	# _apply_general_settings()
	# _apply_video_settings()
	# _apply_input_settings()


# ------------------------------------------------------------------------------
# Internal helpers
# ------------------------------------------------------------------------------

func _load_section(config: ConfigFile, section: String) -> void:
	if not settings.has(section):
		settings[section] = {}

	var section_defaults: Dictionary = settings[section]
	for key in section_defaults.keys():
		settings[section][key] = config.get_value(section, key, section_defaults[key])


func _apply_setting(section: String, key: String, value) -> void:
	match section:
		SECTION_AUDIO:
			_apply_audio_setting(key, value)
		SECTION_GENERAL:
			pass
		SECTION_VIDEO:
			pass
		SECTION_INPUT:
			pass


func _apply_audio_settings() -> void:
	for key in settings[SECTION_AUDIO].keys():
		_apply_audio_setting(key, settings[SECTION_AUDIO][key])


func _apply_audio_setting(key: String, value) -> void:
	match key:
		"master_volume":
			_set_bus_volume_percent("Master", value)
		"music_volume":
			_set_bus_volume_percent("Music", value)
		"effects_volume":
			_set_bus_volume_percent("Effects", value)
		"ui_volume":
			_set_bus_volume_percent("UI", value)
		"output_device":
			AudioServer.output_device = str(value)


func _set_bus_volume_percent(bus_name: StringName, percent_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("SettingsManager: Audio bus not found: %s" % bus_name)
		return

	var linear_value :float = clamp(percent_value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_linear(bus_index, linear_value)
