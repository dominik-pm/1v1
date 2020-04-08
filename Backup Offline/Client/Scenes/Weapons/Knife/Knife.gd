extends Weapon

var player_fired
var base_fire_rate = 0.5
var slow_fire_rate = 1
var alternate_swinging = false
var already_hit = false
var swinging = false

var second_damage

func init():
	reload_rate = 0
	damage = 30
	second_damage = 70
	current_ammo = 10000
	$RecoilResetTimer.wait_time = recoil_reset_time

func shoot_from(transf, dir, velocity, player_name):
	swinging = true
	if dir == Vector3(0,0,0):
		fire_rate = slow_fire_rate
		player_fired = player_name
		alternate_swinging = true
		$AnimationPlayer.play("alternate_swing")
	else:
		fire_rate = base_fire_rate
		player_fired = player_name
		$AnimationPlayer.play("swing")

func fire(transf, dir, player_name):
	pass

func _on_RecoilResetTimer_timeout():
	pass

func _on_AnimationPlayer_animation_finished(anim_name):
	swinging = false
	alternate_swinging = false
	already_hit = false
