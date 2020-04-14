extends Node

var game_hud

var is_spectator = true
var player_id
var player = null
var player_scene = preload("res://Scenes/player/Player.tscn")
var puppet_player = preload("res://Scenes/player/PuppetPlayer/PuppetPlayer.tscn")
var puppet_players = {}
var puppet_nodes_parent = null

var tickrate = 64

# TODO:
# - request_time

func _ready():
	game_hud = get_node("GameHUD")
	
	puppet_nodes_parent = get_parent().get_node("PuppetPlayers")
	$TickrateTimer.wait_time = 1.0/tickrate
	$TickrateTimer.autostart = false
	$TickrateTimer.one_shot = false
	
	# tell the server the we loaded the map
	rpc_id(1, "player_loaded", Network.local_id)

# - Tell the Server ->
func update_self():
	if not is_spectator:
		rpc_unreliable_id(1, "update_player", player.data)

func shoot(dir, power, dmg):
	rpc_id(1, "shoot_bullet", player_id, dir, power, dmg)
func knife(is_alternate):
	rpc_id(1, "knife", player_id, is_alternate)
#func init_weapons(weapons):
# delete
#	rpc_id(1, "set_weapons", player_id, weapons)
func switch_weapon(index):
	rpc_id(1, "select_weapon", player_id, index)
func emit_sound(sound_name):
	rpc_id(1, "emit_sound", player_id, sound_name)
# <- Tell the Server -

# - Server called ->
# to everyone
remote func knifing(pid, is_alternate):
	var p = get_puppet_player(pid)
	if p != null:
		p.knifing(is_alternate)
	else:
		print("knifing: player not instanced")
#remote func set_weapons(pid, weapons):
#	var p = get_puppet_player(pid)
#	p.hand.add_weapons(weapons)
remote func select_weapon(pid, index):
	var p = get_puppet_player(pid)
	if p != null:
		p.hand.update_weapon(index)
	else:
		print("select weapons: player not instanced")
remote func play_sound(pid, sound_name):
	var p = get_puppet_player(pid)
	if p != null:
		p.play_sound(sound_name)
	else:
		print("play sound: player not instanced")
remote func remove_player(pid):
	puppet_players.erase(pid)
	var p = get_puppet_player(pid)
	if p != null:
		p.queue_free()
	else:
		print("remove player: cant remove, becaus no there .-.")
remote func display_status(msg):
	game_hud.display_status(msg)
remote func player_died(pid_killer, pid_died):
	var killer_name = Global.clients[pid_killer].nickname
	var victim_name = Global.clients[pid_died].nickname
	
	# show in killfeed
	game_hud.update_killfeed(killer_name, victim_name)
	
	if pid_died != player_id:
		# otherplayerdied
		var p = get_puppet_player(pid_died)
		if p != null:
			p.die()
		else:
			print("player died: player not instanced")
remote func update_scoreboard(scores):
	game_hud.update_scoreboard(scores)
remote func set_timer(t):
	game_hud.set_timer(t)

# init/puppets
remote func init_self(info):
	is_spectator = false
	player_id = info.id
	player = player_scene.instance()
	get_parent().add_child(player)
	get_parent().spectating(false)
	player.init(info)
	$TickrateTimer.start()
	
	# tell the server that we are ready
	rpc_id(1, "player_ready", Network.local_id)

#remote func init_players(players):
#	# spawn players (instanciate puppet players)
#	puppet_nodes_parent = get_parent().get_node("PuppetPlayers")
#	for pid in players:
#		var p = players[pid]
#		# only init other players
#		if pid != player_id:
#			var new_p = puppet_player.instance()
#			puppet_nodes_parent.add_child(new_p)
#			new_p.init(p)
remote func update_puppet_player(info):
	puppet_players[info.id] = info
	var p = get_puppet_player(info.id)
	if p != null:
		p.update(info)
	else:
		# create new puppet player
		var new_p = puppet_player.instance()
		puppet_nodes_parent.add_child(new_p)
		new_p.init(info)
remote func shoot_bullet_puppet(pid, dir, power):
	get_puppet_player(pid).shoot(dir, power)

# spectating
remote func spectate():
	print("im a spectator")
	yield(get_tree().create_timer(0.1), "timeout")
	get_parent().spectating(true)

# to this player
remote func get_damage(dmg):
	player.get_damage(dmg)
remote func hit_target(dmg):
	player.hit_target(dmg)
remote func killed_target(tid):
	player.killed_target(tid)
	
	# maybe something different idk (current: if i kill someone: the target will explode, if someone else kills someone nothing happens)
	var killed = get_puppet_player(tid)
	killed.die()
remote func respawn_player(pos):
	player.respawn(pos)
remote func get_stunned(enable_stun):
	player.get_stunned(enable_stun)
remote func get_killed():
	is_spectator = true
	player.die()
	get_parent().spectating(true)
# <- Server called -

func get_puppet_player(pid):
	var has_puppet = puppet_nodes_parent.has_node(str(pid))
	if has_puppet:
		return puppet_nodes_parent.get_node(str(pid))
	else:
		return null
		
		## create new puppet player because it doesnt exist yet
		#var new_p = puppet_player.instance()
		#puppet_nodes_parent.add_child(new_p)
		#var dummy_data = player.data.duplicate()
		#dummy_data.id = pid
		#new_p.init(dummy_data) # as dummy data pup in out own -> should get updated in 1 tick anyways
		#return new_p

func _on_TickrateTimer_timeout():
	update_self()
