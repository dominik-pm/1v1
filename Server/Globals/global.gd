extends Node

var current_messenger = null
var game_path = "/root/Map/Game"
var menu_scene = preload("res://UI/MainMenu.tscn")

var clients = {}

func _input(event):
	if event.is_action_pressed("close_application"):
		Network.quit()

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

func save_stats():
	# somehow save the statistics of a player (only makes sense with accounts)
	# also when a player logs in -> hid pid is different
	pass
