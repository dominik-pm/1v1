extends Node

enum MAPS {
	MAP1 = 0,
	OFFLINE = 1
}

var scenes = {
	MAPS.MAP1: preload("res://Game/Maps/Map1/Map1.tscn"),
	MAPS.OFFLINE: preload("res://Game/Maps/Offline/Offline.tscn")
}
