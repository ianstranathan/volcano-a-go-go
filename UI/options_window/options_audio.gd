extends MarginContainer

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const EFFECTS_BUS := &"Effects"
const UI_BUS := &"UI"

@onready var master_row = $AudioVBox/MasterRow
@onready var music_row = $AudioVBox/MusicRow
@onready var effects_row = $AudioVBox/EffectsRow
@onready var ui_row = $AudioVBox/UIRow
@onready var output_device_row = $AudioVBox/OutputDeviceRow


func _ready() -> void:
	_populate_output_devices()
	_load_settings_into_ui()
	_connect_ui_signals()


func _populate_output_devices() -> void:
	output_device_row.clear_items()
	output_device_row.add_item("Default")
	
	var devices := AudioServer.get_output_device_list()
	for device_name in devices:
		if device_name == "Default":
			continue
		output_device_row.add_item(device_name)


func _load_settings_into_ui() -> void:
	master_row.set_value(SettingsManager.get_audio_setting("master_volume", 100.0))
	music_row.set_value(SettingsManager.get_audio_setting("music_volume", 100.0))
	effects_row.set_value(SettingsManager.get_audio_setting("effects_volume", 100.0))
	ui_row.set_value(SettingsManager.get_audio_setting("ui_volume", 100.0))
	
	output_device_row.select_item_by_text(
		SettingsManager.get_audio_setting("output_device", "Default")
	)


func _connect_ui_signals() -> void:
	master_row.value_changed.connect(_on_master_row_value_changed)
	music_row.value_changed.connect(_on_music_row_value_changed)
	effects_row.value_changed.connect(_on_effects_row_value_changed)
	ui_row.value_changed.connect(_on_ui_row_value_changed)
	output_device_row.item_selected.connect(_on_output_device_selected)


func _on_master_row_value_changed(value: float) -> void:
	SettingsManager.set_audio_setting("master_volume", value)


func _on_music_row_value_changed(value: float) -> void:
	SettingsManager.set_audio_setting("music_volume", value)


func _on_effects_row_value_changed(value: float) -> void:
	SettingsManager.set_audio_setting("effects_volume", value)


func _on_ui_row_value_changed(value: float) -> void:
	SettingsManager.set_audio_setting("ui_volume", value)


func _on_output_device_selected(_index: int, text: String) -> void:
	SettingsManager.set_audio_setting("output_device", text)
