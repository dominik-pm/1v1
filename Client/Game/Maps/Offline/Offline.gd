extends Spatial

var player = preload("res://Scenes/player/Player.tscn")

func _ready():
	player = player.instance()
	add_child(player)
	var info = {
		id = 99, 
		position = Vector3(0,3,0), 
		rotation = Vector3(0,0,0), 
		headrotation = Vector3(0,0,0)
	} 
	player.init(info)
