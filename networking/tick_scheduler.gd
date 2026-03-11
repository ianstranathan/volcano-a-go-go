extends Node
class_name TickScheduler

@export var buffer_size: int = 600 # 10 seconds of head-room
var _buffer: Array[Array] = []
var _last_processed_tick: int = -1

func _init() -> void:
	_buffer.resize(buffer_size)
	for i in range(buffer_size):
		_buffer[i] = [] # Initialize each slot with an empty list


func schedule_at(target_tick: int, callback: Callable):
	# -- need to make sure the wait_time_ticks doesn't exceed the size of the buffer
	#    target_tick = NetManager.current_tick + _wait_ticks
	#  =>_wait_ticks = target_tick - NetManager.current_tick
	assert( target_tick - NetManager.current_tick < buffer_size, "Timer duration exceeds circular buffer size (in TickScheduler)")
	var index = target_tick % buffer_size
	_buffer[index].append(callback)


func tick(current_tick: int):
	var index = current_tick % buffer_size
	
	# Extract and clear the bucket immediately
	var callbacks = _buffer[index].duplicate()
	_buffer[index].clear() 

	for c in callbacks:
		c.call()
	
	_last_processed_tick = current_tick

#extends Node
#class_name TickScheduler
#
#var events := {} # tick -> Array[Callable]
#
#
#func schedule(current_tick:int, delay_ticks:int, callback:Callable):
	#var target_tick = current_tick + delay_ticks
#
	#if !events.has(target_tick):
		#events[target_tick] = []
#
	#events[target_tick].append(callback)
#
#
#func tick(current_tick:int):
	#if !events.has(current_tick):
		#return
#
	#var callbacks = events[current_tick]
#
	#for c in callbacks:
		#c.call()
#
	#events.erase(current_tick)
