extends Resource

class_name ItemInterface

#signal used
signal stopped
signal destroyed

@export var use_mode: ItemUseMode


enum ItemUseMode 
{
	INSTANT,       # -- e.g. immediately affects player, like health potion
	ITEM_SPAWNING, # -- ice block, obstruction block, rope ladder
	PLAYER_MOVING  # -- grappling hook
}

var can_use_fn: Callable
var tick_update_fn: Callable
var finished_using_item: bool = false # did the thing being interfaced with stop?

# -- we require a can use, but we're letting the parent (rope, hookshot, potion)
# -- or whatever decide what that means (dependency injection)
func can_use() -> bool:
	if can_use_fn.is_valid():
	#assert(can_use_fn.is_valid(), "ItemInterface.can_use_fn was never assigned")
		return can_use_fn.call()
	return false


# -- we're asserting that every item has a tick_update
# -- (i.e. deterministic _physics_process) but what that looks like
# -- depends on the item
func tick_update(delta_tick: float, command: PlayerCommand) -> void:
	if tick_update_fn.is_valid():
		tick_update_fn.call(delta_tick, command)


#func use():
	#emit_signal("used")


func stop():
	emit_signal("stopped")


func destroy():
	emit_signal("destroyed")
