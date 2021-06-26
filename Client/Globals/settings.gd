# Stores, saves and loads game Settings in an ini-style file
extends Node


#const SAVE_PATH = "res://config.cfg" # in debug
const SAVE_PATH = "user://config.cfg" # on build


var config_file = ConfigFile.new()
var settings = {
	"general": {
		"show_fps": true,
		"show_vel": false
	},
	"player": {
		"mouse_sensitivity": 1.0,
		"fov": 90
	},
	"bindings": {
		"move_forward": 87,
		"move_backward": 83,
		"move_left": 65,
		"move_right": 68,
		"jump": 32,
		"crouch": 16777237,
		"reload": 82,
		"weapon_slot_1": 49,
		"weapon_slot_2": 50,
		"weapon_slot_3": 51,
		"next_weapon": 69,
		"previous_weapon": 81
	},
	"video": {
		"fullscreen": false,
		"msaa": true
	},
	"audio": {
		"sound_volume": 0.5,
		"music_volume": 0.5
	}
}

func _ready():
	#save_settings()
	load_settings()

func set_game_binds():
	for key in settings["bindings"]:
		var value = settings["bindings"][key]
		
		var actionlist = InputMap.get_action_list(key)
		if !actionlist.empty():
			InputMap.action_erase_event(key, actionlist[0])
		
		if str(value) != "":
			var new_key = InputEventKey.new()
			new_key.set_scancode(value)
			InputMap.action_add_event(key, new_key)

func save_settings():
	for section in settings.keys():
		for key in settings[section]:
			config_file.set_value(section, key, settings[section][key])
			#if settings[section][key] != "":
			#	config_file.set_value(section, key, settings[section][key])
			#else:
			#	config_file.set_value(section, key, "")
	
	config_file.save(SAVE_PATH)

func load_settings():
	# Open the file
	var error = config_file.load(SAVE_PATH)
	
	# Check if it opened
	if error != OK:
		print("Failed loading settings file. Error code %s" % error)
		print("Creating a new one...")
		save_settings()
		return
	
	# Retrieve the values and store them in settings
	for section in settings.keys():
		for key in settings[section]:
			var value = config_file.get_value(section, key, "")
			settings[section][key] = value
			#if str(value) != "":
			#	settings[section][key] = value
			#else:
			#	settings[section][key] = ""

func get_setting(category, key):
	return settings[category][key]

func set_setting(category, key, value):
	settings[category][key] = value
