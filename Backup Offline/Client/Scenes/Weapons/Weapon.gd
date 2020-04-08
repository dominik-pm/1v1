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
export var fire_power = 100

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

func shoot_from(transf, dir, velocity, player_name):
	$Muzzle/MuzzleFlash.emit_flash()
	
	if spraying:
		current_spraying_spread += 0.1
		if current_spraying_spread > max_spraying_spread:
			current_spraying_spread = max_spraying_spread
	else:
		spraying = true
	
	$RecoilResetTimer.stop()
	$RecoilResetTimer.start()
	
	
	# more spread when moving
	var velocity_spread = moving_spread*velocity # velocity = between 0-1,... (not exact)
	var spread = current_spraying_spread + velocity_spread
	
	dir = get_spread(dir, spread)
	
	fire(transf, dir, player_name)

func fire(transf, dir, player_name):
	var b = preload_bullet.instance()
	b.init(transf, dir, fire_power, damage, player_name)
	get_tree().root.add_child(b)
#func fire(transf, dir, player_id):
	#if global.is_offline:
	#	global.shoot_bullet_client(player_id, bullet_item_id, transf, dir, fire_power, damage)
	#else:
	#	global.rpc_id(1, "shoot_bullet", player_id, bullet_item_id, transf, dir, fire_power, damage)

func _on_RecoilResetTimer_timeout():
	spraying = false
	current_spraying_spread = 0

# to get a randomized spread
#var old_object = null
func get_spread(d, s):
	return d
	
	## ------
	
	#if old_object != null:
	#	old_object.queue_free()
	##var object = obj.instance()
	#var object = obj.instance()
	#get_node(global.GAME_PATH).add_child(object)
	
	##print(d)
	#object.rotation = d
	##print(object.rotation)
	#object.global_transform.origin = Vector3(0, 50, 0)
	
	var dir = d
	var r
	randomize()
	
	# random up and down spread
	r = sin(randf()*2*PI)*s/100 # r = [-1.0;1.0] multiplied with spread/100
	#object.rotate_object_local(Vector3(1,0,0), r*2*PI)
	
	# random left and right spread
	r = sin(randf()*2*PI)*s/100
	#object.rotate_object_local(Vector3(0,1,0), r*2*PI)
	
	#dir = object.rotation
	dir = dir.normalized()
	
	#old_object = object
	
	return dir
