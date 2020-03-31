extends CanvasLayer

onready var player = $"../"
onready var ammo = $VBoxContainer/Stats/HBoxContainer/AmmoLabel
onready var healthbar = $HealthBar
onready var death_count_label = $VBoxContainer/Stats/VBoxContainer/DeathCountLabel
onready var kill_count_label = $VBoxContainer/Stats/VBoxContainer/KillCountLabel
onready var fps_count_label = $VBoxContainer/Top/FPSCountLabel

var menu_open = false

func _ready():
	show_fps()
	unscope()

func hide():
	for child in get_children():
		if child.has_method('hide'):
			child.hide()

func get_damage():
	return
	var r = rand_range(0, 2)
	if r < 1:
		$DamageIndicator.flip_h = true
	else:
		$DamageIndicator.flip_h = false
	if r < 0.5 or r > 1.5:
		$DamageIndicator.flip_v = true
	else:
		$DamageIndicator.flip_v = false
	
	$AnimationPlayer.play("damage")

func update_ammo(weapon, reloading):
	if weapon.is_in_group("knife"):
		ammo.text = ""
	else:
		if reloading:
			ammo.text = "  / " + str(weapon.clip_size)
			ammo.reload(weapon.reload_rate)
		else:
			ammo.stop_reload()
			var a = weapon.current_ammo
			var clip_size = weapon.clip_size
			var reload_rate = weapon.reload_rate
			ammo.text = str(a) + " / " + str(clip_size)

func hide_ammo():
	ammo.text = ""

func update_health(health):
	healthbar.value = health

func update_kill_count(kill_count):
	kill_count_label.text = "Kills: " + str(kill_count)

#func open_game_menu():
#	player.unscope()
#	menu_open = true
#	$GameMenu.show()
#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#func close_game_menu():
#	player.load_settings()
#	menu_open = false
#	$GameMenu.hide()
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func scope():
	$Scope.visible = true
	$Crosshair.visible = false
func unscope():
	$Scope.visible = false
	$Crosshair.visible = true

func update_fps():
	fps_count_label.text = "FPS: " + str(Engine.get_frames_per_second())
func show_fps():
	update_fps()
	fps_count_label.visible = true
	$UpdateFPSTimer.start()
func hide_fps():
	fps_count_label.visible = false
	$UpdateFPSTimer.stop()

func _on_UpdateFPSTimer_timeout():
	update_fps()
