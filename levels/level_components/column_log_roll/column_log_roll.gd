@tool
extends Node2D

@export var rotation_speed: float = 2.0

#var log_velocity := Vector2(0, angular_velocity * radius)

var _coll_extents: Vector2 = Vector2(50, 50)

@export var coll_extents: Vector2:
	set(value):
		_coll_extents = value
		
		if is_node_ready():
			if $BasePlatform:
				$BasePlatform.coll_extents = value
				if $BasePlatform/Sprite2D:
					$BasePlatform/Sprite2D.material.set_shader_parameter(
						"coll_extents",  _coll_extents)
			
	get:
		return _coll_extents

func _ready() -> void:
	if not Engine.is_editor_hint():
		coll_extents = _coll_extents
		$BasePlatform/Area2D.body_entered.connect( on_body_entered )
		$BasePlatform/Area2D.body_exited.connect( on_body_exited )

var monitored_players : Array[Player] = [null, null, null, null]
func on_body_entered(body: Node) -> void:
	if body is Player:
		if $BasePlatform/Sprite2D.z_index > body.z_index:
			$BasePlatform/Sprite2D.z_index = body.z_index - 1
		var empty_slot = monitored_players.find(null)
		# docs: Returns the index of the first occurrence of what in this array, or -1 if there are none.
		if empty_slot != -1:
			monitored_players[empty_slot] = body
			body.start_log_rolling(100., global_transform.y)
			

func on_body_exited(body: Node) -> void:
	if body is Player:
		var slot = monitored_players.find(body)
		if slot != -1:
			#bo = true
			monitored_players[slot] = null
			body.fall_off_log()

func execute_tick(_delta: float) -> void:
	# Check if anyone has fallen off
	for i in range(monitored_players.size()):
		var player = monitored_players[i]
		
		# Skip empty slots
		if player == null:
			continue
			
		var d =  global_position - player.global_position
		var d_along_normal = d.dot(global_transform.y)
		
		if d_along_normal <= 0:
			player.fall_off_log()
			monitored_players[i] = null
			
			
@export var axis_length := 64.0


@export var debug_draw := false:
	set(value):
		debug_draw = value
		queue_redraw()

func _draw():
	if not debug_draw:
		return
	var len := 300.0
	var x = to_local(global_position + global_transform.x * len)
	var y = to_local(global_position + global_transform.y * len)

	draw_line(Vector2.ZERO, x, Color.RED, 4)
	draw_line(Vector2.ZERO, y, Color.GREEN, 4)

	draw_circle(x, 4, Color.RED)
	draw_circle(y, 4, Color.GREEN)
