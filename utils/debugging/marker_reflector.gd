extends Marker2D


@onready var label: Label = $Label

func _ready() -> void:
	assert(label)

func _process(delta: float) -> void:
	label.text = str( global_position )
