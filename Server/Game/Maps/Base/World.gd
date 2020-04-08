extends Spatial

var game = preload("res://Game/Game.tscn")

var spectating_index = 0
var overview_cam
var in_overview

func _ready():
	overview_cam = $CamOverview
	overview_cam.current = true
	in_overview = true
	
	# add the Game Script
	game = game.instance()
	add_child(game)
	
	# add the Game Mode Script
	var gm = Gamemodes.scenes[Network.SETTINGS["GAMEMODE"]]
	gm = gm.instance()
	add_child(gm)
	
	# init the game script
	game.init(Network.player_ids)

func _input(event):
	#if event.is_action_pressed("ui_cancel"):
	#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("overview_cam") and not in_overview:
		# switch to overview cam
		overview_cam.current = true
		in_overview = true
		var ps = get_puppets()
		ps[spectating_index].spectate(false)
	
	var ps = get_puppets()
	if ps.size() > 0:
		if event.is_action_pressed("spectate_next"):
			overview_cam.current = false
			ps[spectating_index].spectate(false)
			if ps.size() > spectating_index + 1:
				spectating_index = spectating_index + 1
			else:
				spectating_index = 0
			in_overview = false
			ps[spectating_index].spectate(true)
		if event.is_action_pressed("spectate_previous"):
			overview_cam.current = false
			ps[spectating_index].spectate(false)
			if spectating_index >= 1:
				spectating_index = spectating_index - 1
			else:
				spectating_index = ps.size()-1
			in_overview = false
			ps[spectating_index].spectate(true)

func get_puppets():
	var ps = []
	for p in $PuppetPlayers.get_children():
		ps.push_back(p)
	return ps

func _on_DeathArea_body_entered(body):
	if body is PuppetPlayer:
		game.player_died(int(body.name), int(body.name))
