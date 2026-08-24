extends Node2D

class_name ProjectileItemComponent

signal target_position_changed

func tick_update( cmd: PlayerCommand):
	target_position_changed.emit( cmd.aiming_input )
