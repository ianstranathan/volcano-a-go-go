extends Node2D

var swap_projectiles: Array[SwapProjectile] = []
var swap_projectile_count: int = 0
var swap_projectile_2_idx: Dictionary = {}


func _ready() -> void:
	swap_projectiles.resize(50)


func add_swap_projectile(s: SwapProjectile) -> void:
	add_child(s)
	
	# -- I think dynamic arrays already do this but whatever
	if swap_projectile_count >= swap_projectiles.size():
		swap_projectiles.resize(swap_projectiles.size() * 2)
	
	
	swap_projectiles[swap_projectile_count] = s
	swap_projectile_2_idx[s] = swap_projectile_count
	
	# -- bind, didn't know that
	s.tree_exited.connect( _on_projectile_tree_exited.bind(s) )
	swap_projectile_count += 1


func _on_projectile_tree_exited(s: SwapProjectile) -> void:
	if not swap_projectile_2_idx.has(s):
		return
		
	var remove_idx: int = swap_projectile_2_idx[s]
	var last_idx: int = swap_projectile_count - 1
	
	# -- swap and pop
	if remove_idx != last_idx:
		var last_proj: SwapProjectile = swap_projectiles[last_idx]
		swap_projectiles[remove_idx] = last_proj
		swap_projectile_2_idx[last_proj] = remove_idx
	
	swap_projectiles[last_idx] = null
	swap_projectile_2_idx.erase(s)
	swap_projectile_count -= 1


func execute_tick(delta: float) -> void:
	for i in range(swap_projectile_count):
		swap_projectiles[i].execute_tick(delta)
