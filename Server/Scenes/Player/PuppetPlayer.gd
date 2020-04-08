extends KinematicBody

class_name PuppetPlayer

var preloaded_death_effect = preload("res://Scenes/Effects/DeathExplosion.tscn")
var preload_bullet = preload("res://Scenes/Weapons/Bullet/Bullet.tscn")

onready var anim = $AnimationPlayer
onready var hand_anim = $HandAnimation
onready var healthbar = $HealthBar
onready var skel = $Armature/Skeleton
onready var raycol = $raycol
onready var crouchtween = $crouchtween
onready var footcast = $footcast
onready var hand = $Camera/Hand
onready var muzzle = $Camera/PlayerMuzzle
onready var emitting_sounds = $EmittingSounds
onready var sound_emitter_pos = $SoundEmitterPosition

var camera
var headbone
var initial_head_transform

export var BLEND_TIME = 0.1 # for animations

# - movement ->
export var jump_force = 10
var jumping = false
var crouching = false

export var running_speed = 6
export var ACCEL_RUN = 20
export var DEACCEL_RUN = 150
export var ACCEL_AIR = 20
export var DEACCEL_AIR = 0.1
export var crouching_speed = 3
var vel = Vector3()

var grav = -30
var max_grav = -60
# <- movement -

# - PvP ->
var kills = 0
var max_health = 100
var health = max_health
# <- PvP -

var sounds
var data

func _ready():
	pass

func init(info):
	camera = get_node("Camera")
	headbone = skel.find_bone("Head")
	initial_head_transform = skel.get_bone_pose(headbone)
	
	#hand.init(weapons)
	
	update(info)
	
	name = str(info.id)
	$NameTag.set_name(Global.clients[info.id].nickname)
	healthbar.update(health)

func spectate(is_spectating):
	camera.current = is_spectating
	$Armature/Skeleton/Character.visible = !is_spectating

var last_anim = ""
var interpolation_rate = 1.0
func update(info):
	data = info.duplicate()
	
	# position / rotation
	prev_position = global_transform.origin
	global_transform.origin = info.position #global_transform.origin.linear_interpolate(info.position, delta*interpolation_rate)
	rotation = info.rotation#rotation.linear_interpolate(info.rotation, delta*interpolation_rate)
	
	# animation
	if last_anim != info.animation and not crouching:
		anim.play(info.animation)
		last_anim = info.animation
	
	# headrotation
	camera.rotation = info.headrotation
	var current_head_transform = initial_head_transform.rotated(Vector3(-1, 0, 0), -camera.rotation.x)
	skel.set_bone_pose(headbone, current_head_transform)

var prev_position

func _process(delta):
	pass
	# lets say fr = 6, tr = 2
	# then the player could 
	# update its position fr/tr (6/2=3) times 
	# for the distance of (new_loc-cur_loc)/3
	
	# basically xd
	
	#var t = (1.0/delta)/64.0
	#var d = (data.position-prev_position)/t
	
	#global_transform.origin += d
	
	# nononoono
	#global_transform.origin = lerp(global_transform.origin, data.position, delta*2)
	#rotation = rotation.linear_interpolate(data.rotation, delta*interpolation_rate)

func switch_weapon(index):
	hand.switch_weapon(index)

func shoot(dir, power, dmg, p_shot_id):
	var b = preload_bullet.instance()
	var transf = muzzle.global_transform
	b.init(transf, dir, power, dmg, p_shot_id)
	get_tree().root.add_child(b)
func knifing(is_alternate):
	if hand.selected_weapon != null:
		if hand.selected_weapon.item["slot"] == "KNIFE":
			hand.selected_weapon.knife(int(name), is_alternate)
func get_input(delta):
	"""
	# movement
	var target_dir = Vector2(0, 0)
	
	if not (jumping or crouching):
		set_anim(target_dir)
	
	target_dir = -target_dir.normalized().rotated(-rotation.y)
	
	# change acceleration/velocity according to the current state
	var speed
	var acceleration
	var temp_velocity = vel
	temp_velocity.y = 0
	
	if temp_velocity.length() > 1:
		# if moving
		if not jumping:
			acceleration = ACCEL_RUN
			if not is_sound_playing("step"):
				sound_emit("step")
		else:
			acceleration = ACCEL_AIR
	else:
		if not jumping:
			acceleration = DEACCEL_RUN
		else:
			acceleration = DEACCEL_AIR
	
	if jumping:
		# in air
		speed = running_speed
	else:
		# on floor
		if crouching:
			speed = crouching_speed
		else:
			speed = running_speed
	
	
	# apply the velocity
	#temp_velocity = temp_velocity.linear_interpolate(Vector3(target_dir.x, 0, target_dir.y)*speed, acceleration * delta)
	#vel.x = temp_velocity.x
	#vel.y = temp_velocity.y
	
	vel.x = lerp(vel.x, target_dir.x * speed, acceleration*delta)
	vel.z = lerp(vel.z, target_dir.y * speed, acceleration*delta)
	
	vel.y += grav * delta
	if vel.y < max_grav:
		vel.y = max_grav
	
	move_and_slide(vel, Vector3(0, 1, 0))
	
	if is_on_floor() and vel.y < 0:
		vel.y = 0
		jumping = false
	
	var current_head_transform = initial_head_transform.rotated(Vector3(-1, 0, 0), -cam.rotation.x)
	skel.set_bone_pose(headbone, current_head_transform)
	"""

func jump():
	vel.y = jump_force
	anim.play("idle", BLEND_TIME)
	anim.play("jump", BLEND_TIME)
	jumping = true
func crouch():
	anim.play("crouch", BLEND_TIME)
	crouchtween.interpolate_property(raycol.shape, "length", raycol.shape.length, 3.3, 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	crouchtween.interpolate_property(footcast, "translation", footcast.translation, Vector3(0,2.4,0), 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	crouchtween.start()
	crouching = true
func release_crouch():
	crouchtween.interpolate_property(raycol.shape, "length", raycol.shape.length, 5, 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	crouchtween.interpolate_property(footcast, "translation", footcast.translation, Vector3(0,0.6,0), 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	crouchtween.start()
	crouching = false

# was nu ned
func switching_weapons(index):
	hand_anim.play("switch_weapon")
func reloading():
	hand_anim.play("reload")
func shooting():
	hand_anim.play("shoot")
#

func get_damage(amt):
	# update health
	health -= amt
	healthbar.update(health)

func die():
	# effects
	var deatheffect = preloaded_death_effect.instance()
	get_tree().root.add_child(deatheffect)
	deatheffect.global_transform.origin = $Center.global_transform.origin

func respawn(pos):
	health = max_health
	healthbar.update(health)
	
	global_transform.origin = pos

func is_sound_playing(sound_name : String):
	var audioplayer = null
	for audiop in emitting_sounds.get_children():
		if audiop.name == sound_name:
			audioplayer = audiop
			break
	if audioplayer != null:
		return audioplayer.playing

func play_sound(sound_name : String):
	var audioplayer = null
	for audiop in emitting_sounds.get_children():
		if audiop.name == sound_name:
			audioplayer = audiop
			break
	
	if audioplayer != null:
		var db = 0 # maybe add a setting
		audioplayer.unit_db = db
		audioplayer.global_transform.origin = sound_emitter_pos.global_transform.origin
		audioplayer.play()
	else:
		print("no sound with name: " + sound_name)

func set_anim(dir):
	if dir == Vector2(0, 0) and anim.current_animation != "idle":
		anim.play("idle", BLEND_TIME)
	elif dir == Vector2(0, 1) and not (anim.current_animation == "forward" and anim.get_playing_speed() > 0):
		anim.play("forward", BLEND_TIME)
	elif dir == Vector2(1, 1) and not (anim.current_animation == "frontleft" and anim.get_playing_speed() > 0):
		anim.play("frontleft", BLEND_TIME)
	elif dir == Vector2(-1, 1) and not (anim.current_animation == "frontright" and anim.get_playing_speed() > 0):
		anim.play("frontright", BLEND_TIME)
	elif dir == Vector2(1, 0) and anim.current_animation != "left":
		anim.play("left", BLEND_TIME)
	elif dir == Vector2(-1, 0) and anim.current_animation != "right":
		anim.play("right", BLEND_TIME)
	elif dir == Vector2(0, -1) and not (anim.current_animation == "forward" and anim.get_playing_speed() < 0):
		anim.play_backwards("forward", BLEND_TIME)
	elif dir == Vector2(-1, -1) and not (anim.current_animation == "frontleft" and anim.get_playing_speed() < 0):
		anim.play_backwards("frontleft", BLEND_TIME)
	elif dir == Vector2(1, -1) and not (anim.current_animation == "frontright" and anim.get_playing_speed() < 0):
		anim.play_backwards("frontright", BLEND_TIME)
