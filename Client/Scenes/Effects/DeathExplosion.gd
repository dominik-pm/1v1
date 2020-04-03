extends Spatial

func _ready():
	$Particles.one_shot = true
	$Particles.emitting = true
	
	yield(get_tree().create_timer(5), "timeout")
	queue_free()
