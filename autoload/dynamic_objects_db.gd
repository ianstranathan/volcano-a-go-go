extends Node


enum DynamicObjectType{
	ROCK_1,
	ROCK_2,
	ROCK_3,
}

const ROCK_ATLAS := preload("res://assets/tmp/Cave - SmallRocks.png")

const ROCK_ATLAS_REGIONS := {
	DynamicObjectType.ROCK_1: Rect2(106, 79, 131, 128),
	DynamicObjectType.ROCK_2: Rect2(89, 276, 185, 141),
	DynamicObjectType.ROCK_3: Rect2(94, 521, 195, 178),
}
