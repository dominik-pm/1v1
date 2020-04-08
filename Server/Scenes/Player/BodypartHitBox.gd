extends KinematicBody

class_name BodypartHitBox

var player = null
var bodypart

func _ready():
	player = get_parent().get_parent().get_parent().get_parent()
	# the bodypart is called "playerhitbox_head" and we just want "head"
	bodypart = name.substr(name.find("_")+1)
