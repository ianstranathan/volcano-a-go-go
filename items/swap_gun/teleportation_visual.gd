extends Sprite2D

var t = 0

func _ready() -> void:
	material.set_shader_parameter("control", 0)


func _physics_process(delta: float) -> void:
	t += 2. * delta
	# initial_value: Variant, delta_value: Variant, elapsed_time: float, duration: float, trans_type: TransitionType, ease_type: EaseType)
	Tween.interpolate_value(0, 1, t, 1, Tween.TRANS_SINE, Tween.EASE_IN)
	material.set_shader_parameter("control", t)
	if t >= 1.0:
		queue_free()
