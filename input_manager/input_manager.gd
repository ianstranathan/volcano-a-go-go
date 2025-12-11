extends Node2D
class_name InputManager

signal input_source_type_changed

enum InputSourceType{
	CONTROLLER,
	KEYBOARD
}

var current_input_source: InputSourceType = InputSourceType.CONTROLLER


func _input(event: InputEvent) -> void:
	if (current_input_source == InputSourceType.CONTROLLER and
		(event is InputEventKey or event is InputEventMouse)):
		set_input_source(InputSourceType.KEYBOARD)
		# -- something for the UI later
		emit_signal("input_source_type_changed", InputSourceType.KEYBOARD)
	elif (current_input_source == InputSourceType.KEYBOARD and 
		 (event is InputEventJoypadButton or event is InputEventJoypadMotion
		 or event is InputEventJoypadButton)):
		set_input_source(InputSourceType.CONTROLLER)
		# -- something for the UI later
		emit_signal("input_source_type_changed", InputSourceType.CONTROLLER)


func movement_vector():
	# -- NOTE
	# -- may want to force either keyboard or controller, but I don't care right now
	return Input.get_vector("move left", "move right", "move up", "move down") 


func aiming_vector(from_position=null):
	if current_input_source == InputSourceType.CONTROLLER:
		return Input.get_vector("aim left", "aim right", "aim up", "aim down")
	elif current_input_source == InputSourceType.KEYBOARD:
		return (get_global_mouse_position() - from_position)


func just_pressed_action(action_name: String):
	return Input.is_action_just_pressed(action_name)


func just_released_action(action_name: String) -> bool:
	return Input.is_action_just_released(action_name)


var last_pressed_action: StringName
func pressed_action(action_name: String) -> bool: #, return_name=false):
	var rez = Input.is_action_pressed(action_name)
	if rez and (!last_pressed_action or last_pressed_action != action_name):
		last_pressed_action = action_name
	return rez


func get_last_pressed_action() -> StringName:
	return last_pressed_action


func set_input_source(_source_type: InputSourceType):
	if current_input_source != _source_type:
		current_input_source = _source_type


func is_using_keyboard_and_mouse() -> bool:
	return current_input_source == InputSourceType.KEYBOARD


func is_using_controller() -> bool:
	return current_input_source == InputSourceType.CONTROLLER
