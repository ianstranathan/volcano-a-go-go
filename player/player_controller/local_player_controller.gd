extends Node2D
class_name LocalPlayerController

signal input_source_type_changed
signal aim_input_detected
signal inventory_slot_selected(slot_index: int)

var pending_command := PlayerCommand.new()
var input_blocked: bool = false

enum InputSourceType{
	CONTROLLER,
	KEYBOARD
}

var current_input_source: InputSourceType = InputSourceType.CONTROLLER

const DEADZONE := 0.1

func _ready() -> void:
	Events.input_blocked.connect(func(blocked: bool) -> void: input_blocked = blocked
	)
	
func update_command(player_command_ref: PlayerCommand, _delta):
	#@Ian, im pretty sure i had to pass neutral data to block input. this works
	#take a look if theres a better way
	if input_blocked:
		player_command_ref.move_input = Vector2.ZERO
		player_command_ref.jump_pressed = false
		player_command_ref.jump_released = false
		player_command_ref.aiming_input = global_position
		player_command_ref.using_controller = is_using_controller()
		player_command_ref.item_use_pressed = false
		player_command_ref.item_use_held = false
		player_command_ref.sprint_held = false
		player_command_ref.item_dropped = false
		return
		
	player_command_ref.move_input = movement_vector()
	player_command_ref.jump_pressed = just_pressed_action("jump")
	player_command_ref.jump_released = just_released_action("jump")
	player_command_ref.aiming_input = aiming_pos()
	player_command_ref.using_controller = is_using_controller()
	player_command_ref.item_use_pressed = just_pressed_action("use_item")
	player_command_ref.item_use_held = Input.is_action_pressed("use_item")
	player_command_ref.sprint_held = Input.is_action_pressed("sprint")
	player_command_ref.item_dropped = just_pressed_action("drop_item")

func _input(event: InputEvent) -> void:
	if input_blocked:
		return
		
	inventory_slot_input(event)
	# -------------------------------------- change controller types
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
	
	# -------------------------------------- emit_signal if aiming input
	if (current_input_source == InputSourceType.KEYBOARD and 
		event is InputEventMouseMotion):
		emit_signal("aim_input_detected")
	elif (current_input_source == InputSourceType.CONTROLLER and
		  event is InputEventJoypadMotion):
		if abs(event.axis_value) < DEADZONE:
			return
		match event.axis:
			JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
				emit_signal("aim_input_detected")
	
	#if event.is_action_pressed("jump"):
		#pending_command.jump_pressed = true
	## -- this is for short jumps
	#if event.is_action_released("jump"):
		#pending_command.jump_released = true


func movement_vector():
	return Input.get_vector("move_left", "move_right", "move_down", "move_up") 

# -- NOTE
# -- CHANGE ME
## the distance in pixels that the controller can aim to
@export var controller_aiming_chain_length: float = 400.0 

func aiming_vector() -> Vector2:
	var rez := Vector2.ZERO
	if current_input_source == InputSourceType.CONTROLLER:
		rez = (Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down").normalized() *
				controller_aiming_chain_length)
	elif current_input_source == InputSourceType.KEYBOARD:
		# -- NOTE
		# var _from = global_position if !from_position else from_position
		#return (get_global_mouse_position() - _from)
		rez = (get_global_mouse_position() - global_position)
	return rez


func aiming_pos() -> Vector2:
	return (aiming_vector() + global_position)


func just_pressed_action(action_name: String):
	return Input.is_action_just_pressed(action_name)


func just_released_action(action_name: String) -> bool:
	return Input.is_action_just_released(action_name)


var last_pressed_action: StringName
func pressed_action(action_name: String) -> bool: #, return_name=false):
	var rez = Input.is_action_pressed(action_name)
	if rez:
		if !last_pressed_action or last_pressed_action != action_name:
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


func inventory_slot_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	for i in range(5):
		if event.is_action_pressed("inventory_slot_" + str(i + 1)): #ai's way of avoiding nested if statement/ switch - fragile
			inventory_slot_selected.emit(i)
			return
