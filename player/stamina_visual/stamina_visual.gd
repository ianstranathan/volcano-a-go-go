extends Node2D

signal stamina_depleted
signal stamina_started_recharging

@export var seconds_of_stamina: float

@onready var ticks_of_stamina :float = seconds_of_stamina
@onready var current_stamina := ticks_of_stamina

var is_using_stamina: bool = false
var can_recharge: bool = false

# -- how long to wait before we can start recharging?
var recharge_wait_timer: TickTimer = TickTimer.new(0.8)

# -- how long to wait after not using before we hide the stamina bar
var hide_stamina_visual_timer: TickTimer = TickTimer.new(0.5)

# -- juice/ game feel, want to drain slower thann recharge
@export var drain_coeff := 2.0 

func _ready() -> void:
	$Sprite2D.visible = false
	recharge_wait_timer.timeout.connect( func(): 
		can_recharge = true
		stamina_started_recharging.emit())
	hide_stamina_visual_timer.timeout.connect( func():
		$Sprite2D.visible = false)


func use(b: bool):
	# -- player wants to use && staminda is recharged
	is_using_stamina = b
	# -- always show the sprite when the player wants to use stamina 
	if b:
		$Sprite2D.visible = true
	


func update_tick( delta ):
	if $Sprite2D.visible:
		if is_using_stamina:
			current_stamina = max(0.0, current_stamina - (delta * drain_coeff))
			can_recharge = false
			recharge_wait_timer.stop()
			hide_stamina_visual_timer.stop()
			if current_stamina == 0.0:
				stamina_depleted.emit()
		else:
			if !can_recharge and recharge_wait_timer.is_stopped():
				recharge_wait_timer.start()
			if can_recharge:
				if current_stamina < ticks_of_stamina:
					current_stamina = min(ticks_of_stamina, 
										  current_stamina + delta * (1.0 / drain_coeff))
				elif (current_stamina == ticks_of_stamina and 
					hide_stamina_visual_timer.is_stopped()):
					hide_stamina_visual_timer.start()
					
		$Sprite2D.material.set_shader_parameter("progress", 
				current_stamina / seconds_of_stamina)

#extends Node2D
#
#@export var seconds_of_stamina: float
#
#@onready var ticks_of_stamina :float = seconds_of_stamina / NetManager.TICK_RATE # 1 sec / 60 ticks
#@onready var current_stamina := ticks_of_stamina
#
#
#var is_using_stamina: bool = false
#var can_recharge: bool = false
#
## -- how long to wait before we can start recharging?
#var recharge_wait_timer: TickTimer = TickTimer.new(0.8)
#var hide_stamina_visual_timer: TickTimer = TickTimer.new(0.5)
#
## -- juice/ game feel, want to drain slower thann recharge
#@export var drain_coeff := 0.5
#
#func _ready() -> void:
	#recharge_wait_timer.timeout.connect( func(): can_recharge = true)
#
#
#func use(b: bool):
	#is_using_stamina = b
	#$Sprite2D.visible = true
#
#
#func update_tick(_delta):
	#if $Sprite2D.visible:
		#if is_using_stamina: 
			#current_stamina = max(0.0, current_stamina - drain_coeff)
			#can_recharge = false
			#recharge_wait_timer.stop()
			#hide_stamina_visual_timer.stop()
		#else:
			#if !can_recharge and recharge_wait_timer.is_stopped():
				#recharge_wait_timer.start()
			#else:
				#if current_stamina < ticks_of_stamina:
					#current_stamina = min(ticks_of_stamina, 
												#current_stamina + (1.0 / drain_coeff))
				#elif (current_stamina == ticks_of_stamina and 
					#hide_stamina_visual_timer.is_stopped()):
					#hide_stamina_visual_timer.start()
					#
		#$Sprite2D.material.set_shader_parameter("progress", 
				#float(current_stamina) / float(ticks_of_stamina))
