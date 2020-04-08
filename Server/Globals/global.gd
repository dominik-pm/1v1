extends Node

var game_path = "/root/Map/Game"
var menu_scene = preload("res://UI/MainMenu.tscn")

var clients = {}

func _input(event):
	if event.is_action_pressed("close_application"):
		Network.quit()

func save_stats():
	# somehow save the statistics of a player (only makes sense with accounts)
	# also when a player logs in -> hid pid is different
	pass
