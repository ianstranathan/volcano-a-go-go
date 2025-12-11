extends Node

var t = 0.


#func _ready() -> void:
	#var level_extens = get_viewport().size
	# -- make bg sprite size of viewport
	#$Lava.scale = Vector2($Lava.get_viewport().size) / $Lava.get_texture().get_size()
	#$TheLevel.get_children().map( func(child) -> void:
		#child.set_level_extens(Vector2(-level_extens.x / 2., level_extens.x / 2.)))


func _physics_process(delta: float) -> void:
	t += delta


@onready var player_init_pos = $Player.global_position
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		$Player.global_position = player_init_pos


@onready var screen_extens = get_viewport().size
