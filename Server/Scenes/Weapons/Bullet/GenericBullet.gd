extends KinematicBody

class_name GenericBullet

var bullet_hole = preload("res://Scenes/Effects/BulletImpact.tscn")

var player_fired = "99"
var dir = Vector3(0,0,0)
var speed = 0
var damage = 1
var ttl = 5

func _ready():
	$Timer.start(ttl)

func init(t, d, s, dmg, player_name):
	player_fired = player_name
	self.global_transform = t
	self.dir = d
	speed = s
	damage = dmg

# Kinematic Body

func _physics_process(delta):
	var collision = move_and_collide(dir * speed * delta)
	if collision:
		var body = collision.collider
		if body is BodypartHitBox:
			# check if didnt hit own player
			if int(player_fired) != int(body.player.name):
				# find the hit bodypart
				var bodypart = body.bodypart
				
				get_node(Global.game_path).player_hit_player(int(player_fired), int(body.player.name), damage, bodypart)
				
				hit_player()
		else:
			hit_world(collision.position)

func hit_player():
	create_target_hit_effects()
	remove_self()

func hit_world(pos):
	create_bullet_hole(pos)
	remove_self()

func create_target_hit_effects():
	$Sparks.emitting = true

func create_bullet_hole(pos):
	var hole = bullet_hole.instance()
	get_tree().root.add_child(hole)
	hole.global_transform.origin = pos - dir.normalized()*0.1

func remove_self():
	# hide the bullet and free it after 1 second
	$MeshInstance.hide()
	set_physics_process(false)
	$CollisionShape.disabled = true
	yield(get_tree().create_timer(1), "timeout")
	queue_free()

func _on_Timer_timeout():
	queue_free()
