extends Node

enum MODES {
	MODE_1v1 = 0,
	MODE_DM = 1
}

var scenes = {
	MODES.MODE_1v1: preload("res://Game/Gamemodes/1v1/1v1.tscn"),
	MODES.MODE_DM: preload("res://Game/Gamemodes/dm/dm.tscn")
}
