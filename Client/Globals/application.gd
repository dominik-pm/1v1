extends Node

func _ready():
	settings.load_settings()
	
	# dont know where to put it
	OS.window_fullscreen = settings.get_setting("video", "fullscreen")
	if settings.get_setting("video", "msaa"):
		get_viewport().msaa = Viewport.MSAA_8X
	else:
		get_viewport().msaa = Viewport.MSAA_DISABLED

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		Network.disconnect_from_server()
		get_tree().quit()

func _input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		settings.set_setting("video", "fullscreen", !settings.get_setting("video", "fullscreen"))
		OS.window_fullscreen = settings.get_setting("video", "fullscreen")
