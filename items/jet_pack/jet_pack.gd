extends Node2D


@export var item_interface: ItemInterface
@export var accl_curve: Curve
var player_ref: Player
var g

func _ready() -> void:
	#----------------------------------- item interface / dependency injection
	item_interface.tick_update_fn = tick_update
	item_interface.stopped.connect(on_item_stopped)
	item_interface.destroyed.connect( func():
		call_deferred("queue_free"))

	if player_ref:
		g = player_ref.get_g()

var interpolant := 0.0
@export var delta_increase_rate: float = 1.0

func accl_sample(delta: float) -> float:
	interpolant += delta * delta_increase_rate
	interpolant = clamp(interpolant, 0., 1)
	return accl_curve.sample(interpolant)


func tick_update(delta: float, cmd: PlayerCommand):
	if cmd.item_use_held:
		if !$Sprite2D.visible:
			# -- turn off for this client and the host's version
			$Sprite2D.show()
			$GPUParticles2D.visible = true
			$GPUParticles2D.emitting = true
			show_on_interpolated()
		player_ref.velocity.y -= 1.5 * g * accl_sample( delta ) * delta
	else:
		if $Sprite2D.visible:
			$Sprite2D.hide()
			$GPUParticles2D.visible = false
			$GPUParticles2D.emitting = false
			show_on_interpolated( false )
		interpolant = 0.0


@rpc("any_peer", "reliable")
func show_on_interpolated(b=true):
	if !multiplayer.is_server():
		if b:
			$Sprite2D.show()
			$GPUParticles2D.visible = true
			$GPUParticles2D.emitting = true
		else:
			$Sprite2D.hide()
			$GPUParticles2D.visible = false
			$GPUParticles2D.emitting = false


func on_item_stopped():
	show_on_interpolated( false )
	$MovementOverrideComponent.finish()


func set_player_ref(p: Player) -> void:
	player_ref = p
