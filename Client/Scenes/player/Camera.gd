extends Camera

var amplitude
export var shake : = false setget set_shake
export(float, EASE) var DAMP_EASING : = 1.0

export var shake_amplitude : = 0.25
export var shake_duration := 0.25

var duration : = 0.25 setget set_duration

export var recoil_amplitude : = 0.25
export var recoil_duration : = 1.0
var recoil_back_duration
var recoil_up_duration
var recoil_up = false
var recoil_down = false
var up_down_ration = 4

export (NodePath) var player
export (NodePath) var hud
var timer

func _ready():
	player = get_node(player)
	hud = get_node(hud)
	
	timer = $TimerShake
	
	recoil_up_duration = (recoil_duration/up_down_ration)/2
	recoil_back_duration = recoil_duration/2
	
	set_process(false)
	self.shake_duration = shake_duration
	amplitude = shake_amplitude

func _process(delta):
	var damping := ease(timer.time_left / timer.wait_time, DAMP_EASING)
	
	if recoil_up:
		# move camera up
		rotate_x(amplitude * up_down_ration * damping * delta)
		player.clamp_aim()
		#player.camera_change.y = -amplitude * up_down_ration * damping
	elif recoil_down:
		# move camera slowly back
		rotate_x(-amplitude * damping * delta)
		player.clamp_aim()
		#player.camera_change.y = amplitude * damping # with old aiming system (bugged)
	else:
		# shake
		v_offset = rand_range(amplitude, -amplitude) * damping
		h_offset = rand_range(amplitude, -amplitude) * damping
		
	
	#offset = Vector2( # in 2d
	#	rand_range(amplitude, -amplitude) * damping,
	#	rand_range(amplitude, -amplitude) * damping)

func _on_TimerShake_timeout():
	if recoil_up:
		recoil_up = false
		recoil_down = true
		self.duration = recoil_back_duration
		self.shake = true
	else:
		recoil_down = false
		self.shake = false


func _on_camera_shake_requested(multiplier):
	amplitude = shake_amplitude * multiplier
	self.duration = shake_duration
	self.shake = true

func _on_camera_recoil_requested(multiplier):
	amplitude = recoil_amplitude * multiplier * 0.5
	recoil_up = true
	self.duration = recoil_up_duration
	self.shake = true

func set_duration(value: float) -> void:
	if timer != null:
		shake_duration = value
		timer.wait_time = shake_duration

func set_shake(value: bool) -> void:
	shake = value
	set_process(shake)
	#offset = 0 # in 2d
	h_offset = 0
	v_offset = 0
	if shake:
		timer.start()
