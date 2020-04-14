extends Node

var current_messenger = null
var game_path = "/root/Map/Game"
var menu_scene = preload("res://Scenes/MainMenu/MainMenu.tscn")

var clients = {}

func _ready():
	pass

func set_messenger(msger):
	current_messenger = msger
func message(msg):
	if current_messenger == null:
		print(msg)
	else:
		if current_messenger.has_method("message"):
			current_messenger.message(msg)
		else:
			print("current messenger ("+current_messenger.name+") has not implemented 'message' yet!")
