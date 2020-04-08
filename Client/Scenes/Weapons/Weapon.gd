extends Spatial

class_name Weapon

var preload_bullet = preload("res://Scenes/Weapons/Bullet/Bullet.tscn")

export var shooting_sound = "m4"
export var scopeable = false
var in_scope = false
export var scope_fov = 30
export var fire_rate = 0.5
export var clip_size = 8
export var reload_rate = 1
export var damage = 10
export var fire_power = 250

# recoil/spraying
export var moving_spread = 1.0
export var max_spraying_spread = 1.0
export var recoil_reset_time = 1.0
var current_spraying_spread = 0
var spraying = false

var muzzle

var current_ammo
var item # database entry
	
func _ready():
	init()

func init():
	muzzle = get_node("Muzzle")
	$RecoilResetTimer.wait_time = recoil_reset_time
	
	current_ammo = 0
	current_ammo = clip_size

func shoot(transf, dir):
	$Muzzle/MuzzleFlash.emit_flash()
	
	if spraying:
		current_spraying_spread += 0.1
		if current_spraying_spread > max_spraying_spread:
			current_spraying_spread = max_spraying_spread
	else:
		spraying = true
	
	$RecoilResetTimer.stop()
	$RecoilResetTimer.start()
	
	fire(transf, dir)

func fire(transf, dir):
	var b = preload_bullet.instance()
	b.init(transf, dir, fire_power)
	get_tree().root.add_child(b)
#func fire(transf, dir, player_id):
	#if global.is_offline:
	#	global.shoot_bullet_client(player_id, bullet_item_id, transf, dir, fire_power, damage)
	#else:
	#	global.rpc_id(1, "shoot_bullet", player_id, bullet_item_id, transf, dir, fire_power, damage)

func _on_RecoilResetTimer_timeout():
	spraying = false
	current_spraying_spread = 0
