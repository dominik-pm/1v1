extends KinematicBody

class_name PuppetPlayer

var preloaded_death_effect = preload("res://Scenes/Effects/DeathExplosion.tscn")
var preloaded_ragdoll = preload("res://Scenes/Effects/Ragdoll.tscn")
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
var acc = 0

var grav = -30
var max_grav = -60
# <- movement -

# - network lerping ->
var lerp_active = false
var time = 0
var time_to_lerp
var new_pos
var new_rot
var new_hrot
var last_pos
var last_rot
var last_hrot
# <- network lerping -

# - PvP ->
var max_health = 100
var health = max_health
# <- PvP -

var sounds

func _ready():
	pass

func init(info, tickrate):
	time_to_lerp = 1.0 / tickrate
	
	camera = get_node("Camera")
	headbone = skel.find_bone("Head")
	initial_head_transform = skel.get_bone_pose(headbone)
	
	var w = info.weapons
	w.push_back("knife")
	hand.init(w)
	
	update(info)
	
	name = str(info.id)
	$NameTag.set_name(name)
	$HealthBar.update(health)

func set_spectate(is_spectating):
	camera.current = is_spectating
	$Armature/Skeleton/Character.visible = !is_spectating

var last_anim = ""
func update(info):
	time = 0
	
	# movement/rotation
	last_pos = new_pos
	new_pos = info.position
	last_rot = new_rot
	new_rot = info.rotation
	last_hrot = new_hrot
	new_hrot = info.headrotation
	lerp_active = true
	
	# animation
	if last_anim != info.animation and not crouching:
		anim.play(info.animation)
		last_anim = info.animation
	
	# headrotation
	camera.rotation = info.headrotation
	var current_head_transform = initial_head_transform.rotated(Vector3(-1, 0, 0), -camera.rotation.x)
	skel.set_bone_pose(headbone, current_head_transform)

func _physics_process(delta):
	if lerp_active:
		time += delta
		if new_pos != last_pos:
			lerp_movement()
		if new_rot != last_rot:
			lerp_rotation()
		if new_hrot != last_hrot:
			lerp_head_rotation()
func lerp_movement():
	var perc = time/time_to_lerp
	if last_pos:
		global_transform.origin = lerp(last_pos, new_pos, perc)
	else:
		global_transform.origin = new_pos
func lerp_rotation():
	var perc = time/time_to_lerp
	if last_rot:
		rotation = lerp(last_rot, new_rot, perc)
	else:
		rotation = new_rot
func lerp_head_rotation():
	var perc = time/time_to_lerp
	if last_hrot:
		camera.rotation = lerp(last_hrot, new_hrot, perc)
	else:
		camera.rotation = new_hrot
	var current_head_transform = initial_head_transform.rotated(Vector3(-1, 0, 0), -camera.rotation.x)
	skel.set_bone_pose(headbone, current_head_transform)

func shoot(dir, power):
	var b = preload_bullet.instance()
	var transf = muzzle.global_transform
	b.init(transf, dir, power)
	get_tree().root.add_child(b)


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

# game called -> server called
func switching_weapons(index):
	hand_anim.play("switch_weapon")
func reloading():
	#sound_emit("reload")
	hand_anim.play("reload")
func shooting():
	#sound_emit(hand.selected_weapon.shooting_sound)
	hand_anim.play("shoot")
func knifing(is_alternate):
	if hand.selected_weapon != null:
		if hand.selected_weapon.item["slot"] == "KNIFE":
			hand.selected_weapon.knife(is_alternate)
#

func get_damage(amt, player_fired, bodypart):
	# update health
	health -= amt
	healthbar.update(health)

func die():
	# effects
	var deatheffect = preloaded_death_effect.instance()
	get_tree().root.add_child(deatheffect)
	deatheffect.global_transform.origin = $Center.global_transform.origin
	
	# add a ragdoll
	#var ragdoll = preloaded_ragdoll.instance()
	#get_tree().root.add_child(ragdoll)
	#ragdoll.rotation = rotation
	#ragdoll.init(global_transform.origin)
	
	# if spectating this puppet -> tell the world to spectate another one
	if camera.current:
		get_parent().get_parent().try_spectate_anyone()
	
	queue_free()

func is_sound_playing(sound_name : String):
	var audioplayer = null
	for audiop in emitting_sounds.get_children():
		if audiop.name == sound_name:
			audioplayer = audiop
			break
	if audioplayer != null:
		return audioplayer.playing

func sound_emit(sound_name : String):
	play_sound(sound_name)

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
