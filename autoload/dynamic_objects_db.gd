@tool
extends Node

# -----------------------------------------------------------------------------
enum DynamicObjectType { ROCK, LANTERN, SKULL }


@export var profiles: Dictionary = {
	DynamicObjectType.ROCK: preload("res://levels/dynamic_objects/data/rock/dynamic_rock.tres"),
	DynamicObjectType.LANTERN: preload("res://levels/dynamic_objects/data/lantern/dynamic_lantern.tres")
}
	#DynamicObjectType.ROCK: preload("res://data/objects/rock_profile.tres"),
	#DynamicObjectType.LANTERN: preload("res://data/objects/lantern_profile.tres"),
	#DynamicObjectType.SKULL: preload("res://data/objects/skull_profile.tres"),
#}

func get_profile(type: DynamicObjectType) -> DynamicObjectProfile:
	return profiles.get(type)
