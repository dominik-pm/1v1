extends Spatial

var game = preload("res://Game/Game.tscn")

var is_spectator = false
var spectating_index = 0

func _ready():
	# add the Game Script
	var g = game.instance()
	add_child(g)

func _input(event):
	if is_spectator:
		if event.is_action_pressed("spectate_next") or event.is_action_pressed("spectate_previous"):
			var ps = get_puppets()
			if ps.size() > 0:
				ps[spectating_index].set_spectate(false)
				if event.is_action_pressed("spectate_next"):
					if ps.size() > spectating_index + 1:
						spectating_index = spectating_index + 1
					else:
						spectating_index = 0
				elif event.is_action_pressed("spectate_previous"):
					if spectating_index >= 1:
						spectating_index = spectating_index - 1
					else:
						spectating_index = ps.size()-1
				ps[spectating_index].set_spectate(true)

func spectating(is_spectating):
	is_spectator = is_spectating
	if is_spectating:
		print("told to spectate")
		try_spectate_anyone()
	else:
		var ps = get_puppets()
		for p in ps:
			p.set_spectate(false)

var spec_tries = 0
func try_spectate_anyone():
	if spec_tries > 100:
		print("cant find player to spectate")
	var ps = get_puppets()
	if ps.size() > 0:
		spec_tries = 0
		disable_current_cam()
		ps[0].set_spectate(true)
	elif is_spectator:
		spec_tries += 1
		yield(get_tree().create_timer(0.1), "timeout")
		try_spectate_anyone()

func spectate_player(pid):
	disable_current_cam()
	var p = game.get_puppet_player(pid)
	p.set_spectate(true)

func get_puppets():
	var ps = []
	for p in $PuppetPlayers.get_children():
		ps.push_back(p)
	return ps

func disable_current_cam():
	var c = get_viewport().get_camera()
	if c != null:
		c.current = false
