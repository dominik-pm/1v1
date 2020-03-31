# Stores, saves and loads game Settings in an ini-style file
extends Node


const SAVE_PATH = "res://config.cfg" # in debug
#const SAVE_PATH = "user://config.cfg" # on build


var config_file = ConfigFile.new()
var settings = {
	"video": {
		"fullscreen": false,
		"msaa": true
	},
	"audio": {
		"sound_volume": 0.5,
		"music_volume": 0.5
	},
	"player": {
		"mouse_sensitivity": 1,
		"fov": 90,
		"show_fps": true
	}
}

func _ready():
	#load_settings()
	pass

func save_settings():
	for section in settings.keys():
		for key in settings[section]:
			config_file.set_value(section, key, settings[section][key])
	
	config_file.save(SAVE_PATH)

func load_settings():
	# Open the file
	var error = config_file.load(SAVE_PATH)
	
	# Check if it opened
	if error != OK:
		print("Failed loading settings file. Error code %s" % error)
		return
	
	# Retrieve the values and store them in settings
	for section in settings.keys():
		for key in settings[section]:
			settings[section][key] = config_file.get_value(section, key, null)

func get_setting(category, key):
	return settings[category][key]

func set_setting(category, key, value):
	settings[category][key] = value
