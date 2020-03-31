extends Control

export(NodePath) var start_menu
var current_menu
var previous_menu

export(NodePath) var settings_button_path
export(NodePath) var settings_menu_path
var settings_btn

func _ready():
	# open start menu
	if start_menu != null:
		open_menu(get_node(start_menu))
	else:
		print("no start menu assigned")
	
	# get buttons
	if settings_button_path == null:
		print("no settings button assigned")
	settings_btn = get_node(settings_button_path)
	
	# connect buttons
	settings_btn.connect("pressed", self, "_on_settingsbutton_pressed")


func _on_settingsbutton_pressed():
	SFX.play_from_bank("ui_click3")
	open_menu(get_node(settings_menu_path))
	get_node(settings_menu_path).init_setting_values()
# <--

func open_menu(menu):
	if current_menu != null:
		current_menu.visible = false
	menu.visible = true
	previous_menu = current_menu
	current_menu = menu
func open_previous_menu():
	if previous_menu != null:
		open_menu(previous_menu)
