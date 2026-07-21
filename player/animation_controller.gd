class_name PlayerAnimationController
extends Node

@export var body: AnimatedSprite2D

var current_animation: StringName = &""
var current_state: Player.MovementStates = Player.MovementStates.IDLE


func set_movement_state(new_state: Player.MovementStates) -> void:
	current_state = new_state

	var next_animation := animation_for_state(new_state)
	play_animation(next_animation)


func animation_for_state(state: Player.MovementStates) -> StringName:
	
	match state:
		Player.MovementStates.IDLE:
			return &"idle"

		Player.MovementStates.WALKING, \
		Player.MovementStates.RUNNING:
			return &"run"

		Player.MovementStates.JUMPING, \
		Player.MovementStates.ITEM_MOVING:
			return &"jump"
			
		Player.MovementStates.FALLING:
			return &"falling"
			
		Player.MovementStates.WALL_SLIDING:
			return &"wall_sliding"
			
		Player.MovementStates.LEDGE_GRABBING:
			return &"ledge_grabbing"	
		_:
			return &"idle"

func set_facing_direction(horizontal_direction: float) -> void:
	if is_zero_approx(horizontal_direction):
		return

	body.flip_h = horizontal_direction < 0.0
	
func play_animation(animation_name: StringName) -> void:
	if current_animation == animation_name:
		return

	current_animation = animation_name
	body.play(animation_name)
