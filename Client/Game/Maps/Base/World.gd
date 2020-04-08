extends Spatial

var game = preload("res://Game/Game.tscn")

func _ready():
	# add the Game Script
	var g = game.instance()
	add_child(g)
