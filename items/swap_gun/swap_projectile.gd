extends Node2D

class_name SwapProjectile

@onready var teleport_visual: PackedScene = preload("res://items/swap_gun/teleportation_visual.tscn")

var origin_player_ref: Player
var dist: float = 0
var dist_thresh = 15000

var dir: Vector2
var speed: float = 1000

func _ready() -> void:
	assert( origin_player_ref )
	assert( dir )
	global_position = origin_player_ref.global_position + 50 * dir
	global_rotation = Vector2.RIGHT.angle_to( dir )
	$Area2D.body_entered.connect( on_body_entered )


# -- I don't think it's likely that we'll ever be shooting into space, but
# -- just in case
func on_body_entered( body ) -> void:
	#print(body)
	#print(origin_player_ref)
	#print(body == origin_player_ref)
	
	if body is Player:
		if body != origin_player_ref:
			swap(body)
	else:
		#print(is_multiplayer_authority())
		#print(body == origin_player_ref)
		# -- do some effect
		queue_free()

# -- ✔
func execute_tick( delta: float):
	# -- step along dir with network tick
	var ds = delta * speed
	dist += ds
	global_position += ds * dir
	if dist > dist_thresh:
		queue_free()



func swap(body):
	var pos_other_player = body.global_position
	var pos_player_shooting = origin_player_ref.global_position
	body.global_position = pos_player_shooting
	origin_player_ref.global_position = pos_other_player
	var teleport_visual_A = teleport_visual.instantiate()
	var teleport_visual_B = teleport_visual.instantiate()
	
	var curr_scene = get_tree().current_scene
	curr_scene.add_child(teleport_visual_A)
	curr_scene.add_child(teleport_visual_B)
	
	teleport_visual_A.global_position = body.global_position
	teleport_visual_B.global_position = origin_player_ref.global_position
	queue_free()
