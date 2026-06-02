extends Node
class_name ItemSpawnComponent


#signal prediction_hidden
#signal prediction_cancelled

var spawn_id: int = -1
var is_predicted_hidden: bool = false

# -- NOTE
# -- I don't think this should default to true, but then we
# -- have to account for toggling this in items placed from editor
var is_active: bool = true
@onready var pickup_item_parent: Node2D = get_parent()


func activate() -> void:
	toggle_on_or_off( true )


func deactivate() -> void:
	toggle_on_or_off( false)


func toggle_on_or_off( b: bool) -> void:
	is_active = b
	is_predicted_hidden = false
	pickup_item_parent.visible = b
	pickup_item_parent.get_node("Area2D").set_deferred("monitoring", b)
	pickup_item_parent.get_node("Area2D").set_deferred("monitorable", b)


func predict_hide() -> void:
	is_predicted_hidden = true
	if pickup_item_parent:
		pickup_item_parent.hide()
	# -- world pickup item manager connects to this in _ready
	#prediction_hidden.emit()


func cancel_predict_hide() -> void:
	if not is_active: 
		return
		
	is_predicted_hidden = false
	
	if pickup_item_parent:
		pickup_item_parent.show()

	#prediction_cancelled.emit()
