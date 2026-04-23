extends MarginContainer

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const EFFECTS_BUS := &"Effects"
const UI_BUS := &"UI"

@onready var master_row = $AudioVBox/MasterRow
@onready var music_row = $AudioVBox/MusicRow
@onready var effects_row = $AudioVBox/EffectsRow
@onready var ui_row = $AudioVBox/UIRow


func _ready() -> void:
	_load_bus_values()
	
	master_row.value_changed.connect(_on_master_row_value_changed)
	music_row.value_changed.connect(_on_music_row_value_changed)
	effects_row.value_changed.connect(_on_effects_row_value_changed)
	ui_row.value_changed.connect(_on_ui_row_value_changed)


func _load_bus_values() -> void:
	_load_row_from_bus(master_row, MASTER_BUS)
	_load_row_from_bus(music_row, MUSIC_BUS)
	_load_row_from_bus(effects_row, EFFECTS_BUS)
	_load_row_from_bus(ui_row, UI_BUS)


func _load_row_from_bus(row, bus_name: StringName) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return
	
	var linear_value := AudioServer.get_bus_volume_linear(bus_index)
	row.set_value(linear_value * 100.0)


func _set_bus_from_row_value(bus_name: StringName, row_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return
	
	AudioServer.set_bus_volume_linear(bus_index, row_value / 100.0)


func _on_master_row_value_changed(value: float) -> void:
	_set_bus_from_row_value(MASTER_BUS, value)


func _on_music_row_value_changed(value: float) -> void:
	_set_bus_from_row_value(MUSIC_BUS, value)


func _on_effects_row_value_changed(value: float) -> void:
	_set_bus_from_row_value(EFFECTS_BUS, value)


func _on_ui_row_value_changed(value: float) -> void:
	_set_bus_from_row_value(UI_BUS, value)
