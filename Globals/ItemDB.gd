extends Node

const ICON_PATH = "res://Assets/Weapons/Icons/"

# weapons have at least
# - an icon
# - a slot (PRIMARY, SECONDARY, KNIFE)
# - a scene

const WEAPONS = {
	"pistol": {
		"icon": ICON_PATH + "pistol.png",
		"slot": "SECONDARY",
		"scene": preload("res://Scenes/Weapons/Pistol/Pistol.tscn")
	},
	"m4": {
		#"icon": ICON_PATH + "m4.png"
		"icon": ICON_PATH + "pistol.png",
		"slot": "PRIMARY",
		"scene": preload("res://Scenes/Weapons/Pistol/Pistol.tscn")
	},
	"uzi": {
		"icon": ICON_PATH + "uzi.png"
	},
	"awp": {
		"icon": ICON_PATH + "awp.png"
	},
	"shotgun": {
		"icon": ICON_PATH + "shotgun.png"
	},
	"knife": {
		"icon": ICON_PATH + "knife.png",
		"slot": "KNIFE",
		"scene": preload("res://Scenes/Weapons/Knife/Knife_Base.tscn")
	},
	
	"error": {
		"slot": "error"
	}
}

func get_item(item_id):
	if item_id in WEAPONS:
		return WEAPONS[item_id]
	else:
		return WEAPONS["error"]

func get_id(item):
	for i in WEAPONS:
		if WEAPONS[i] == item:
			return i
	return "error"
