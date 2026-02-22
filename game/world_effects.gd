#extends Node2D
#
#"""
#Effects that happen over and over again
#&&
#are player specific
#will be pooled
#"""
#
#
#@export var players_container: Node2D
#
## -- lookup container
#var effects_container = {}
#
## -- all the effects that the player will do over and over again
#@onready var recurring_effects_arr = [Effects.EffectNames.LANDING_SMOKE,
									  #Effects.EffectNames.WALL_JUMP]
#
#func initialize_recurring_player_vfx():
	## for each player and for each recurring effect
	## make such an effect and hide it for later
	#for player in players_container.get_children():
		#var _id = player.name.to_int()
		#effects_container[_id] = {}
		#for effect_enum in recurring_effects_arr:
			#var _effect = Effects.effects.get(effect_enum).instantiate()
			#add_child(_effect)
			#var effect_data = {
				#"node":      _effect,
				#"sprite":    _effect.get_node("AnimatedSprite2D"),
				#"component": _effect.get_node("VfxEffectComponent")
			#}
			#effects_container[_id][effect_enum] = effect_data
	#
#
#func _ready() -> void:
	#Events.world_effect.connect( do_effect )
	#initialize_recurring_player_vfx()
#
#
#func do_effect(player_id: int, effect_type: Effects.EffectNames, pos: Vector2, flip: bool):
	#assert( Effects.effects.has(effect_type))
	#
	#effects_container[player_id][effect_type]["sprite"].flip_h = flip
	#effects_container[player_id][effect_type]["node"].global_position = pos
	#effects_container[player_id][effect_type]["component"].start.call()

extends Node2D


class PlayerEffect:
	var node: Node2D
	var sprite: AnimatedSprite2D
	var component: VfxEffectComponent

@export var players_container: Node2D
var effects_container = {}

@onready var recurring_effects_arr = [
	Effects.EffectNames.LANDING_SMOKE,
	Effects.EffectNames.WALL_JUMP,
	Effects.EffectNames.DIRECTION_CHANGE
]

func initialize_recurring_player_vfx():
	for player in players_container.get_children():
		var _id = player.name.to_int()
		effects_container[_id] = {}
		
		for effect_enum in recurring_effects_arr:
			var _effect = Effects.effects.get(effect_enum).instantiate()
			add_child(_effect)
			
			# 2. Create the class instance instead of a Dictionary
			var data = PlayerEffect.new()
			data.node = _effect
			data.sprite = _effect.get_node("AnimatedSprite2D")
			data.component = _effect.get_node("VfxEffectComponent")
			
			effects_container[_id][effect_enum] = data


func _ready() -> void:
	Events.world_effect.connect(do_effect)


func do_effect(player_id: int, effect_type: Effects.EffectNames, pos: Vector2, flip: bool):
	var player_set = effects_container.get(player_id)
	if not player_set:
		return
	
	var effect: PlayerEffect = player_set.get(effect_type)
	if not effect: 
		return

	effect.sprite.flip_h = flip
	effect.node.global_position = pos
	effect.component.start.call()
