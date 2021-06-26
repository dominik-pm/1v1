extends CanvasLayer

onready var player = $"../"
onready var ammo = $WeaponSlots/VBoxContainer/Ammo/AmmoLabel
onready var bullet_icon = $WeaponSlots/VBoxContainer/Ammo/BulletIcon
onready var healthbar = $HealthBar
onready var fps_count_label = $VBoxContainer/Top/FPSCountLabel
onready var slots = $WeaponSlots
onready var dmg_indicator = $DamageIndicator
onready var anim = $AnimationPlayer
onready var scope_overlay = $Scope
onready var crosshair = $Crosshair
onready var fps_timer = $UpdateFPSTimer
onready var game_menu = $GameMenu
onready var vel_label = $VelocityLabel
onready var vel_timer = $VelocityLabel/VelCheckingInterval


var menu_open = false

func _ready():
	unscope()
	show_fps(settings.get_setting("general", "show_fps"))
	show_velocity(settings.get_setting("general", "show_vel"))

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
	if weapon.item["slot"] == "KNIFE":
		ammo.text = ""
		ammo.stop_reload()
		bullet_icon.visible = false
	else:
		bullet_icon.visible = true
		if reloading:
			ammo.text = ""# "  / " + str(weapon.clip_size)
			ammo.reload(weapon.reload_rate)
		else:
			ammo.stop_reload()
			var a = weapon.current_ammo
			var clip_size = weapon.clip_size
			var reload_rate = weapon.reload_rate
			ammo.text = str(a) + " / " + str(clip_size)

func hide_ammo():
	ammo.text = ""
	bullet_icon.visible = false

func update_weapon(index):
	slots.select_slot(index)

func update_health(health):
	healthbar.value = health

#func update_killfeed(killer, victim):
#	killfeed.update_feed(killer, victim)

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
	show_fps(settings.get_setting("general", "show_fps"))
	show_velocity(settings.get_setting("general", "show_vel"))

func scope():
	scope_overlay.visible = true
	crosshair.visible = false
func unscope():
	scope_overlay.visible = false
	crosshair.visible = true

func show_fps(is_on):
	fps_count_label.visible = is_on
	if is_on:
		update_fps()
		fps_timer.start()
	else:
		fps_timer.stop()
func update_fps():
	fps_count_label.text = "FPS: " + str(Engine.get_frames_per_second())
func _on_UpdateFPSTimer_timeout():
	update_fps()

func show_velocity(is_on):
	vel_label.visible = is_on
	if is_on:
		vel_timer.start()
	else:
		vel_timer.stop()
func _on_VelCheckingInterval_timeout():
	var xvel = player.vel.x
	var zvel = player.vel.z
	vel_label.text = str(int((xvel*xvel)+(zvel*zvel)))
