extends Node

func _ready():
	settings.load_settings()
	
	# dont know where to put it
	OS.window_fullscreen = settings.get_setting("video", "fullscreen")
	if settings.get_setting("video", "msaa"):
		get_viewport().msaa = Viewport.MSAA_8X
	else:
		get_viewport().msaa = Viewport.MSAA_DISABLED

func _input(event):
	pass
