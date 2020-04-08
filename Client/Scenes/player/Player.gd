extends KinematicBody

class_name Player

var preloaded_death_effect = preload("res://Scenes/Effects/DeathExplosion.tscn")

onready var anim = $AnimationPlayer
onready var hand_anim = $HandAnimation
onready var cam = $Camera
onready var skel = $Armature/Skeleton
onready var raycol = $raycol
onready var crouchtween = $crouchtween
onready var footcast = $footcast
onready var hand = $Camera/Hand
onready var muzzle = $Camera/PlayerMuzzle
onready var emitting_sounds = $EmittingSounds
onready var sound_emitter_pos = $SoundEmitterPosition
onready var status_hud = $StatusHUD


var data = { 
	id = 99, 
	position = Vector3(0,3,0), 
	rotation = Vector3(0,0,0), 
	headrotation = Vector3(0,0,0)
}

var hud
var game
var headbone
var initial_head_transform

export var BLEND_TIME = 0.1 # for animations

# - management ->
var can_aim = true
var can_move = true
# <- management -

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
export var HEADSHOT_MULTIPLIER = 1.5
export var BODYSHOT_MULTIPLIER = 1.0
export var LIMBSHOT_MULTIPLIER = 0.8

var sens = 1
var fov = 90
var kills = 0
var deaths = 0
var max_health = 100
var health = max_health
var switching_weapons = false

var scoping = false
# <- PvP -

# - recoil ->
signal request_camera_shake
signal request_camera_recoil
var recoil = false
# <- recoil -

var sounds

func _ready():
	#init("Player1", ["m4", "pistol", "knife"])
	pass

func init(info):
	data = info
	game = get_parent().get_node("Game")
	
	hud = get_node("HUD")
	
	sounds = {
		"damaged": $PlayerSounds/damage.stream,
		"reload": $PlayerSounds/reload.stream,
		"weapon_switch": $PlayerSounds/weapon_switch.stream,
		"hit_target": $PlayerSounds/hit_target.stream
	}
	
	update_settings()
	
	self.connect("request_camera_shake", cam, "_on_camera_shake_requested")
	self.connect("request_camera_recoil", cam, "_on_camera_recoil_requested")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	headbone = skel.find_bone("Head")
	#cam.translation = skel.get_bone_global_pose(headbone).origin # wrong?
	initial_head_transform = skel.get_bone_pose(headbone)
	
	var weapons = ["m4", "pistol", "knife"]
	hand.init(weapons)
	game.init_weapons(weapons)
	hud.init_weapons(weapons)
	
	name = str(info.id) # TODO
	
	hud.update_health(health)
	hud.update_kill_count(kills)
	hud.update_death_count(deaths)
	
	$Armature/Skeleton/Character.visible = false

func display_status(msg):
	status_hud.display_status(msg)

func _input(event):
	get_action(event)
	if can_aim:
		aim(event)

func aim(event):
	# aim
	if event is InputEventMouseMotion:
		var movement = event.relative
		rotate_y((-movement.x * sens)*0.02)
		cam.rotation.x += (-movement.y * sens)*0.02
		clamp_aim()

func get_action(event):
	# scope
	if event.is_action_pressed("scope") and hand.is_selected_weapon_scopeable():
		if scoping:
			unscope()
		else:
			scope()
	
	# reload
	if event.is_action_pressed("reload"):
		hand.reload()
	
	# change weapons
	if event.is_action_pressed("weapon_slot_1"):
		hand.select_slot("PRIMARY")
	elif event.is_action_pressed("weapon_slot_2"):
		hand.select_slot("SECONDARY")
	elif event.is_action_pressed("weapon_slot_3"):
		hand.select_slot("KNIFE")
	elif event.is_action_pressed("next_weapon"):
		hand.next_weapon()
	elif event.is_action_pressed("previous_weapon"):
		hand.previous_weapon()

func clamp_aim():
	cam.rotation.x = clamp(cam.rotation.x, -PI/2, PI/2)

func _process(delta):
	get_input(delta)
	data.position = global_transform.origin
	data.headrotation = cam.rotation
	data.rotation = rotation

func get_input(delta):
	if can_move:
		# shooting
		if Input.is_action_pressed("shoot") and not switching_weapons and hand.selected_weapon != null:
			if hand.selected_weapon.item["slot"] != "KNIFE":
				var muzzle_transform = muzzle.get_global_transform()
				var dir = muzzle_transform.origin-cam.get_global_transform().origin
				dir = dir.normalized()
				hand.shoot(muzzle_transform, dir, vel.length())
			else:
				hand.knife(false)
		
		# knife alternate
		if Input.is_action_pressed("alternate_knife"):
			if hand.selected_weapon.item["slot"] == "KNIFE":
				hand.knife(true)
	
	# movement
	var target_dir = Vector2(0, 0)
	
	if can_move:
		# get the desired movement direction
		if Input.is_action_pressed("forward"):
			target_dir.y += 1
		if Input.is_action_pressed("backward"):
			target_dir.y -= 1
		if Input.is_action_pressed("left"):
			target_dir.x += 1
		if Input.is_action_pressed("right"):
			target_dir.x -= 1
	
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
	
	# change the state
	if can_move:
		if Input.is_action_just_pressed("jump") and footcast.is_colliding():
			# jump
			vel.y = jump_force
			anim.play("idle", BLEND_TIME)
			anim.play("jump", BLEND_TIME)
			data.animation = "jump"
			jumping = true
	if Input.is_action_pressed("crouch") and not (crouching or jumping):
		# crouch
		anim.play("crouch", BLEND_TIME)
		data.animation = "crouch"
		crouchtween.interpolate_property(raycol.shape, "length", raycol.shape.length, 3.3, 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouchtween.interpolate_property(footcast, "translation", footcast.translation, Vector3(0,2.4,0), 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouchtween.start()
		crouching = true
	elif (not Input.is_action_pressed("crouch") or jumping) and crouching:
		# release crouch
		crouchtween.interpolate_property(raycol.shape, "length", raycol.shape.length, 5, 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouchtween.interpolate_property(footcast, "translation", footcast.translation, Vector3(0,0.6,0), 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouchtween.start()
		crouching = false
	
	move_and_slide(vel, Vector3(0, 1, 0))
	
	if is_on_floor() and vel.y < 0:
		vel.y = 0
		jumping = false
	
	var current_head_transform = initial_head_transform.rotated(Vector3(-1, 0, 0), -cam.rotation.x)
	skel.set_bone_pose(headbone, current_head_transform)

func switching_weapons(index):
	switching_weapons = true
	hud.update_weapon(index)
	SFX.play_sample(sounds["weapon_switch"], -15.0)
	hand_anim.play("switch_weapon")
	game.switch_weapon(index) # tell the network

func reloading():
	SFX.play_sample(sounds["reload"], -20.0)
	hand_anim.play("reload")

func shooting(dir, power):
	game.shoot(dir, power, hand.selected_weapon.damage)
	sound_emit(hand.selected_weapon.shooting_sound)
	hand_anim.play("shoot")
func knifing(is_alternate):
	game.knife(is_alternate)
	sound_emit(hand.selected_weapon.shooting_sound)

# server called ->
func hit_target(dmg):
	print("Hit target for " + str(dmg) + " damage!")
	SFX.play_sample(sounds["hit_target"], 0.0)
func killed_target(tid):
	kills = kills + 1
	hud.update_kill_count(kills)
func get_damage(amt):
	health -= amt
	# play sound
	SFX.play_sample(sounds["damaged"], 0.0)
	# damage indicator
	hud.get_damage()
	# update health
	hud.update_health(health)
func die():
	deaths = deaths + 1
	hud.update_death_count(deaths)
func remove_kills(amt):
	kills -= amt
	hud.update_kill_count(kills)
func respawn(pos):
	health = max_health
	hud.update_health(health)
	
	hand.reset(["m4", "pistol", "knife"])
	hud.init_weapons(["m4", "pistol", "knife"])
	
	global_transform.origin = pos
func get_stunned(enable_stun):
	can_move = !enable_stun
func update_killfeed(killer, victim):
	hud.update_killfeed(killer, victim)
# <- server called

func is_sound_playing(sound_name : String):
	var audioplayer = null
	for audiop in emitting_sounds.get_children():
		if audiop.name == sound_name:
			audioplayer = audiop
			break
	if audioplayer != null:
		return audioplayer.playing

func sound_emit(sound_name : String):
	game.emit_sound(sound_name)
	play_sound(sound_name)

func play_sound(sound_name : String):
	# theoretically this can be a AudioStreamPlayer sound (doesnt have to be spatial)
	
	var audioplayer = null
	for audiop in emitting_sounds.get_children():
		if audiop.name == sound_name:
			audioplayer = audiop
			break
	
	if audioplayer != null:
		var db = SFX.get_soundfx_decibel()
		audioplayer.unit_db = db
		audioplayer.global_transform.origin = sound_emitter_pos.global_transform.origin
		audioplayer.play()
	else:
		print("no sound with name: " + sound_name)

func unscope():
	hud.unscope()
	cam.fov = fov
	scoping = false
func scope():
	hud.scope()
	cam.fov = hand.get_selected_weapon_scopefov()
	scoping = true

func update_settings():
	sens = settings.get_setting("player", "mouse_sensitivity")
	fov = settings.get_setting("player", "fov")
	cam.fov = fov

func _on_HandAnimation_animation_finished(anim_name):
	if anim_name == "switch_weapon":
		switching_weapons = false

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
	data.animation = anim.current_animation
