extends KinematicBody

class_name GenericBullet

var bullet_hole = preload("res://Scenes/Effects/BulletImpact.tscn")

var dir = Vector3(0,0,0)
var speed = 0
var ttl = 5

func _ready():
	$Timer.start(ttl)

func init(t, d, s):
	self.global_transform = t
	self.dir = d
	speed = s

# Kinematic Body

func _physics_process(delta):
	var collision = move_and_collide(dir * speed * delta)
	if collision:
		if collision.collider is BodypartHitBox:
			hit_player()
			if collision.collider.player is Bot:
				collision.collider.get_damage(20)
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
