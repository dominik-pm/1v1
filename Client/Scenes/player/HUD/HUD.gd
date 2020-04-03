extends CanvasLayer

onready var player = $"../"
onready var ammo = $VBoxContainer/Stats/HBoxContainer/AmmoLabel
onready var healthbar = $HealthBar
onready var kill_count_label = $VBoxContainer/Stats/VBoxContainer/Kills/KillCountLabel
onready var death_count_label = $VBoxContainer/Stats/VBoxContainer/Deaths/DeathCountLabel
onready var fps_count_label = $VBoxContainer/Top/FPSCountLabel
onready var slots = $WeaponSlots
onready var dmg_indicator = $DamageIndicator
onready var anim = $AnimationPlayer
onready var scope_overlay = $Scope
onready var crosshair = $Crosshair
onready var fps_timer = $UpdateFPSTimer
onready var game_menu = $GameMenu


var menu_open = false

func _ready():
	game_menu.hide_menu()
	unscope()
	if settings.get_setting("general", "show_fps"):
		show_fps()
	else: 
		hide_fps()

func init_weapons(weapons):
	slots.init_icons(weapons)

func hide():
	for child in get_children():
		if child.has_method('hide'):
			child.hide()

func get_damage():
	var r = rand_range(0, 2)
	if r < 1:
		dmg_indicator.flip_h = true
	else:
		dmg_indicator.flip_h = false
	if r < 0.5 or r > 1.5:
		dmg_indicator.flip_v = true
	else:
		dmg_indicator.flip_v = false
	
	anim.play("damage")

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

func update_weapon(index):
	slots.select_slot(index)

func update_health(health):
	healthbar.value = health

func update_kill_count(kill_count):
	kill_count_label.text = str(kill_count)

func update_death_count(death_count):
	death_count_label.text = str(death_count)

func _input(event):
	if event.is_action_pressed("toggle_menu"):
		if game_menu.visible:
			close_game_menu()
		else:
			open_game_menu()

func open_game_menu():
	player.unscope()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.can_aim = false
	player.can_move = false
	menu_open = true
	game_menu.show_menu()

func close_game_menu():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.can_aim = true
	player.can_move = true
	menu_open = false
	game_menu.hide_menu()
	if settings.get_setting("general", "show_fps"):
		show_fps()
	else: 
		hide_fps()

func scope():
	scope_overlay.visible = true
	crosshair.visible = false
func unscope():
	scope_overlay.visible = false
	crosshair.visible = true

func update_fps():
	fps_count_label.text = "FPS: " + str(Engine.get_frames_per_second())
func show_fps():
	update_fps()
	fps_count_label.visible = true
	fps_timer.start()
func hide_fps():
	fps_count_label.visible = false
	fps_timer.stop()

func _on_UpdateFPSTimer_timeout():
	update_fps()
