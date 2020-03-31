extends Spatial

var playercam

func _ready():
	playercam = get_node("Player1").find_node("Camera")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("switch_cam"):
		if playercam.current:
			playercam.current = false
			get_node("Camera").current = true
		else:
			playercam.current = true
			get_node("Camera").current = false
