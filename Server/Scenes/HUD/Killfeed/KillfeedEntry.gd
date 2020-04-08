extends HBoxContainer

var ttl = 10
var timer = null
onready var killfeed = $"../../"
onready var anim = $AnimationPlayer

func _ready():
	if timer != null:
		timer.start()

func init(killer, victim):
	timer = Timer.new()
	timer.wait_time = ttl
	timer.autostart = false
	add_child(timer)
	timer.connect("timeout", self, "_on_TimeoutTimer_timeout")
	$Killer.text = str(killer)
	$Victim.text = str(victim)

func _on_TimeoutTimer_timeout():
	anim.play("FadeOut")

func _on_AnimationPlayer_animation_finished(anim_name):
	killfeed.clear_entry(self)
