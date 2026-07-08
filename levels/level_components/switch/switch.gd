extends Node2D


# -- let's say it goes doen by half it's extents
@export var door: Node2D

@onready var animated_platform = $AnimatedPlaceholderPlatform
@onready var extents: Vector2 = animated_platform.coll_extents

@onready var path_2d: Path2D = $Path2D

enum SwitchType{
	IMMEDIATE,
	PRESSURE
}
@export var switch_type: SwitchType = SwitchType.PRESSURE

func _ready() -> void:
	if path_2d.curve == null:
		path_2d.curve = Curve2D.new()
	
	path_2d.curve.clear_points()
	while path_2d.curve.point_count < 2:
		path_2d.curve.add_point(Vector2.ZERO)
	
	# -- we sink half way down
	var h_y = extents.y / 2.0
	path_2d.curve.set_point_position(1, Vector2(0, h_y))
	
	# -- trigger area is halfway shifted up on platform
	$Area2D/CollisionShape2D.shape.size = extents
	$Area2D.position = Vector2(0., -h_y) 
	
	$Area2D.body_entered.connect( on_body_entered )
	$Area2D.body_exited.connect( on_body_exited )
	

var has_been_stepped_on_at_least_once = false
var dir = 1.0
func on_body_entered( body ) -> void:
	if body is Player:
		# -- let the door decide it's own stuff, just let it know
		# -- it should open (1) rather than close ( -1 )
		door.switch_pressed( dir )
		has_been_stepped_on_at_least_once = true
		match switch_type:
			SwitchType.IMMEDIATE:
				# -- we can just turn off the area stuff, right
				$Area2D.set_deferred("monitoring", false)
				$Area2D.set_deferred("monitorable", false)
			SwitchType.PRESSURE:
				pass


func on_body_exited( body ) -> void:
	if body is Player:
		# -- we don't care if it's an immediate switch, so just check this case
		if switch_type == SwitchType.PRESSURE:
			var num_players_on_switch = $Area2D.get_overlapping_bodies().size()
			if num_players_on_switch == 0:
				$AnimatedPlaceholderPlatform.reverse()
			
		

func execute_tick( delta: float) -> void:
	# -- switch is either immediate or pressure
	# -- if it's a pressure we don't want the ONE_SHOT to start until
	# -- it's been stepped on
	# -- after that it can just oscillate bet
	if has_been_stepped_on_at_least_once:
		$AnimatedPlaceholderPlatform.execute_tick( delta )
