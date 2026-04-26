extends CanvasLayer
@onready var tabs: TabContainer = $Root/CenterContainer/WindowPanel/Margin/WindowVBox/Tabs

func _ready() -> void:
	hide()
	tabs.tab_changed.connect(_on_tabs_tab_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()


func open() -> void:
	show()
	Events.emit_signal("input_blocked", true)

func close() -> void:
	hide()
	Events.emit_signal("input_blocked", false)

func toggle() -> void:
	if visible:
		close()
	else:
		open()
		
func _on_tabs_tab_changed(_tab_index: int) -> void:
	Events.emit_signal("play_local_sound", AudioDb.LocalSoundId.UI_CLICK,0,1)
