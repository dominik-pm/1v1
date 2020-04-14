extends Control

onready var gamemodes_dropdown = $VBoxContainer/HBoxContainer/GameModes
onready var maps_dropdown = $VBoxContainer/HBoxContainer2/Maps

func _ready():
	# init gamemodes
	for gamemode in Gamemodes.MODES:
		gamemodes_dropdown.add_item(str(gamemode))

	# init maps
	for map in Maps.MAPS:
		maps_dropdown.add_item(str(map))
	
	gamemodes_dropdown.select(Network.SETTINGS["GAMEMODE"])
	maps_dropdown.select(Network.SETTINGS["MAP"])

func _on_GameModes_item_selected(id):
	print("selected gamemode: " + str(id))
	Network.SETTINGS["GAMEMODE"] = id

func _on_Maps_item_selected(id):
	print("selected map: " + str(id))
	Network.SETTINGS["MAP"] = id
