extends KinematicBody

class_name BodypartHitBox

var player = null

func _ready():
	player = get_parent().get_parent().get_parent().get_parent()

func get_damage(amt):
	var bodypart = name.substr(name.find("_")+1)
	var d = amt
	if bodypart == "head":
		d *= 2.0
	elif bodypart == "body":
		d *= 1.0
	elif bodypart == "limb":
		d *= 0.8
	player.get_damage(d)
