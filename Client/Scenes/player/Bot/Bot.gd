extends Player

class_name Bot

var death_explosion = preload("res://Scenes/Effects/DeathExplosion.tscn")
var ragdoll = preload("res://Scenes/Effects/Ragdoll.tscn")

func _ready():
	init("Bot1")

func init(n):
	self.connect("request_camera_shake", cam, "_on_camera_shake_requested")
	self.connect("request_camera_recoil", cam, "_on_camera_recoil_requested")
	
	headbone = skel.find_bone("Head")
	#cam.translation = skel.get_bone_global_pose(headbone).origin # wrong?
	initial_head_transform = skel.get_bone_pose(headbone)
	
	name = n
	$NameTag.set_name(name)
	$HealthBar.update(health)
	
	var weapons = ["m4", "pistol", "knife"]
	data.weapons = weapons
	hand.init(data.weapons)

func update_settings():
	pass

func clamp_aim():
	pass

func aim(event):
	pass

func switching_weapons(index):
	hand_anim.play("switch_weapon")

func _input(event):
	if event.is_action_pressed("ui_left"):
		die()

func get_action(event):
	pass

func get_input(delta):
	# shooting
	if false:
		if Input.is_action_pressed("shoot") and not switching_weapons and hand.selected_weapon != null:
			var muzzle_transform = muzzle.get_global_transform()
			var dir = muzzle_transform.origin-cam.get_global_transform().origin
			dir = dir.normalized()
			hand.shoot_from_pos(muzzle_transform, dir, vel.length())
	
	# get the desired movement direction
	var target_dir = Vector2(0, 0)
	if false:
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
		else:
			acceleration = ACCEL_AIR
	else:
		if not jumping:
			acceleration = DEACCEL_RUN
		else:
			acceleration = DEACCEL_AIR
	
	if jumping:
		# in air
		speed = AIR_STRAVE_SPEED
	else:
		# on floor
		if crouching:
			speed = crouching_speed
		else:
			speed = RUNNING_SPEED
	
	
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
	if false:
		# jump
		vel.y = jump_force
		anim.play("idle", BLEND_TIME)
		anim.play("jump", BLEND_TIME)
		jumping = true
	if false:
		# crouch
		anim.play("crouch", BLEND_TIME)
		crouchtween.interpolate_property(raycol.shape, "length", raycol.shape.length, 3.3, 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouchtween.interpolate_property(footcast, "translation", footcast.translation, Vector3(0,2.4,0), 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouchtween.start()
		crouching = true
	elif (not true or jumping) and crouching:
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

func get_damage(amt):
	# logic
	health -= amt
	$HealthBar.update(health)
	if health <= 0:
		health = 0
		die()
	

func die():
	# effects
	var deatheffect = death_explosion.instance()
	get_tree().root.add_child(deatheffect)
	deatheffect.global_transform.origin = $Center.global_transform.origin
	
	# add a ragdoll
	var rd = ragdoll.instance()
	rd.init(global_transform.origin, rotation)
	get_tree().root.add_child(rd)
	
	# respawn
	respawn(Vector3(rand_range(-10, 10), 6, rand_range(-10, 10)))

func respawn(pos):
	health = max_health
	$HealthBar.update(health)
	hand.reset(data.weapons)
	global_transform.origin = pos
func switch_weapons():
	switching_weapons = true
	$HandAnimation.play("switch_weapon")

func unscope():
	#$HUD.unscope()
	#cam.fov = fov
	scoping = false
func scope():
	#$HUD.scope()
	#cam.fov = hand.get_selected_weapon_scopefov()
	scoping = true
