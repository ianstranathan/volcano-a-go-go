extends HBoxContainer

signal value_changed(value: float)

@export var label_text: String = "Setting"
@export_range(0, 100, 1) var slider_value: float = 100

@onready var name_label: Label = $NameLabel
@onready var slider: HSlider = $Slider
@onready var value_label: Label = $ValueLabel


func _ready() -> void:
	name_label.text = label_text
	slider.value = slider_value
	_update_value_label(slider_value)
	
	slider.value_changed.connect(_on_slider_value_changed)


func set_value(value: float) -> void:
	slider_value = clamp(value, 0.0, 100.0)
	
	if slider != null:
		slider.value = slider_value
	
	_update_value_label(slider_value)


func get_value() -> float:
	return slider.value


func _on_slider_value_changed(value: float) -> void:
	slider_value = value
	_update_value_label(value)
	value_changed.emit(value)


func _update_value_label(value: float) -> void:
	value_label.text = "%d%%" % roundi(value)
