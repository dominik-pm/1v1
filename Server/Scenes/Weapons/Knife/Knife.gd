extends Weapon

var base_fire_rate = 0.5
var slow_fire_rate = 1
var alternate_swinging = false
var already_hit = false
var swinging = false

var second_damage

var anim
var p

func init():
	reload_rate = 0
	damage = 30
	second_damage = 70
	current_ammo = 10000
	$RecoilResetTimer.wait_time = recoil_reset_time
	anim = $AnimationPlayer

func shoot(pos, dir, vel, player):
	print("knife can not shoot .-.")
	pass

func knife(pid, is_alt):
	p = pid
	swinging = true
	if is_alt:
		fire_rate = slow_fire_rate
		alternate_swinging = true
		anim.play("alternate_swing")
	else:
		fire_rate = base_fire_rate
		anim.play("swing")

func fire(transf, dir, player):
	pass

func _on_RecoilResetTimer_timeout():
	pass

func _on_AnimationPlayer_animation_finished(anim_name):
	swinging = false
	alternate_swinging = false
	already_hit = false

func _on_Blade_body_entered(body):
	if swinging and not already_hit:
		if body is BodypartHitBox and str(body.player.name) != str(p):
			var bodypart = body.bodypart
			var pid2 = body.player.name
			already_hit = true
			get_node(Global.game_path).player_hit_player(int(p), int(pid2), damage, bodypart)
