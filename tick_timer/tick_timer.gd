class_name TickTimer
extends Node

signal timeout

#Gameplay Script
	  #│
	  #│ connect()
	  #▼
#TickTimer
	  #│
	  #│ schedules
	  #▼
#TickScheduler
	  #│
	  #│ executes at tick
	  #▼
#TickTimer._on_timeout()
	  #│
	  #│ emits signal
	  #▼
#Gameplay Script callback

@export var wait_time: float = 1.0
@export var one_shot := true
@export var autostart := false

# -- need to pull this from NetManager
const TICK_RATE := 1.0 / 60.0
var running := false

var wait_time_ticks := 0
var target_time_ticks = -1
var _generation := 0

var time_left: float:
	get:
		return get_time_left()

# ------------------------------------------------------------------------------

func _init(_wait_time: float, is_one_shot: bool=true) -> void:
	wait_time = _wait_time
	one_shot = is_one_shot


func _ready():
	if autostart:
		start()


func start(time := -1.0):
	var duration = wait_time if time <= 0 else time
	wait_time_ticks = seconds_to_ticks(duration)
	
	running = true
	_generation += 1 # -- id to rreject callback conditionally
	target_time_ticks = NetManager.current_tick + wait_time_ticks
	_schedule_internal( NetManager.current_tick + wait_time_ticks)


func _schedule_internal(target_tick: int):
	NetManager.tick_scheduler.schedule_at(target_tick,
										  func(): _on_timeout(_generation))


func _on_timeout(gen: int):
	if gen != _generation or !running:
		return

	timeout.emit()

	if one_shot:
		stop()
	else:
		_schedule_internal( wait_time_ticks )


func stop():
	running = false
	_generation += 1 # invalidate scheduled callbacks


func is_stopped() -> bool:
	return !running


func seconds_to_ticks(seconds:float) -> int:
	return int(round(seconds / TICK_RATE))


func ticks_left() -> int:
	return (target_time_ticks - NetManager.current_tick)


func get_time_left() -> float:
	if !running:
		return 0.0
	
	var tl = ticks_left()

	if tl <= 0:
		return 0.0

	return float(tl) * TICK_RATE


func normalized_time():
	return 1. - (get_time_left() / wait_time)
