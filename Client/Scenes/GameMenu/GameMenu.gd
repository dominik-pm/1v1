extends Control

func _ready():
	pass

func _on_MenuBtn_pressed():
	Network.disconnect_from_server()
	get_tree().change_scene_to(Global.menu_scene)

func _on_LeaveBtn_pressed():
	Network.disconnect_from_server()
	get_tree().quit()

func _on_Settings_pressed():
	$SettingsMenu.show_menu()

func update_player_settings():
	get_parent().player.update_settings()

func hide_menu():
	hide()
	$SettingsMenu.hide_menu()

func show_menu():
	show()
