extends Node

var players_nodes_parent = null

onready var hud = $ServerHUD

var puppet_player = preload("res://Scenes/Player/PuppetPlayer.tscn")

var players_invincible = false
var game_started = false

# Game Mode
var gm

# players that are connected to the network (on the beginning)
var player_count

# all clients in game (players and spectators)
var clients = {}
# spectating the game
var spectators = {}
# playing in game
var players = {}
var player_weapons = {}

var players_loaded = 0
var players_ready = 0
var empty_player_info = { 
	id = 99, 
	position = Vector3(0,3,0), 
	rotation = Vector3(0,0,0), 
	headrotation = Vector3(0,0,0),
	animation = "idle",
	weapons = ["m4", "pistol"]
}

var tickrate = 64
const END_TIME = 6

func _ready():
	player_count = Network.player_ids.size()
	
	var delta = 1.0/tickrate
	$TickrateTimer.wait_time = delta
	$TickrateTimer.autostart = false
	$TickrateTimer.one_shot = false


# called once the map is loaded (with the players currently connected to the network)
func init(player_ids):
	# get some nodes (we know now that every node loaded because the map called this method)
	gm = get_parent().get_node("Gamemode")
	players_nodes_parent = get_parent().get_node("PuppetPlayers")

# to tell a player to instance itself
func init_player(pid):
	players[pid] = empty_player_info.duplicate()
	players[pid].id = pid
	clients[pid] = {id = pid}
	rpc_id(pid, "init_self", players[pid])

# when a player loaded the map and the game hasnt started, init this player
# otherwhise add him to the spectators
remote func player_loaded(pid):
	if not game_started:
		init_player(pid)
		gm.init_player(pid)
	else:
		new_client_ready(pid)
		
# when everyone initialized themself, we can tell the gamemode to start
remote func player_ready(pid):
	players_ready += 1
	if players_ready == player_count:
		$TickrateTimer.start()
		gm.start_game()
		game_started = true
	# idk
	#elif players_ready > players.size():
	#	if is_player(pid):
	#		print("reinstanced player from 1v1 currently")
	#	else:
	#		print("a spectator joined")

func new_client_ready(pid):
	# add the player to the spectators
	clients[pid] = {id = pid}
	spectators[pid] = {id = pid}
	
			## tell him the players
			#rpc_id(pid, "init_players", players)
	
	# tell him that he is a spectator
	rpc_id(pid, "spectate")
func client_disconnected(pid):
	clients.erase(pid)
	Global.message(Global.clients[pid].nickname + " disconnected!")
	
	# check if he was a player/spectator
	if is_player(pid):
		players.erase(pid)
		gm.player_disconnected(pid)
		# he is a player (remove puppet)
		remove_player_puppet(pid)
		# tell the clients to remove the puppet
		call_rpc("remove_player", pid)
	else:
		# he was a spectator, so remove him from the dictionary 
		spectators.erase(pid)

# - Gamemode called ->
func display_status(msg):
	call_rpc("display_status", msg)
	Global.message(msg)
func start_timer(t):
	# -- set our own timer --
	call_rpc("set_timer", t)
func update_scoreboard(s):
	# -- update our own --
	call_rpc("update_scoreboard", s)
func reset_player(pid, pos):
	rpc_id(pid, "respawn_player", pos)
func kill_player(pid):
	# transfer him over to the spectators
	spectators[pid] = players[pid].duplicate()
	players.erase(pid)
	
	# tell him to get killed
	rpc_id(pid, "get_killed")
func respawn_player(pid):
	# transfer him over from the spectators to the players
	players[pid] = spectators[pid].duplicate()
	spectators.erase(pid)
	
	# init him again
	init_player(pid)
func game_ended():
	Network.current_state = Network.STATE.game_ended
	stun_players(true)
	$GameMenu.show()
func stun_players(getting_stunned):
	for pid in players:
		rpc_id(pid, "get_stunned", getting_stunned)
func stun_players_for(time):
	stun_players(true)
	yield(get_tree().create_timer(time), "timeout")
	stun_players(false)
# <- Gamemode called -

# - Player called ->
remote func shoot_bullet(p_shot_id, dir, power, dmg):
	var puppet_player = get_puppet_player(p_shot_id)
	if puppet_player != null:
		# locally, shoot a bullet from the right puppet
		puppet_player.shoot(dir, power, dmg, p_shot_id)
		
		# tell the clients that an other player shot
		for pid in clients:
			if pid != p_shot_id:
				rpc_id(pid, "shoot_bullet_puppet", p_shot_id, dir, power)
	else:
		print("shoot: puppet not instanced yet")
remote func update_player(info):
	if players.has(info.id):
		# different?
		players[info.id].position = info.position
		players[info.id].rotation = info.rotation
		players[info.id].headrotation = info.headrotation
		players[info.id].animation = info.animation
remote func knife(pid, is_alternate):
	# tell the clients
	for p in clients:
		if p != pid:
			rpc_id(p, "knifing", pid, is_alternate)
	
	# update own puppet
	var p = get_puppet_player(pid)
	if p != null:
		p.knifing(is_alternate)
	else:
		print("knife: puppet not instanced yet")
#remote func set_weapons(pid, weapons):
#	# this method could be useless
#	
#	player_weapons[pid] = {weapons=weapons}
#	
#	# tell the clients
#	for p in clients:
#		if p != pid:
#			rpc_id(p, "set_weapons", pid, weapons)
#	
#	# update own puppet
#	var p = get_puppet_player(pid)
#	if puppet_player != null:
#		p.hand.add_weapons(weapons)
#	else:
#		print("set weapons: puppet not instanced yet")
remote func select_weapon(pid, index):
	# tell the clients
	for p in clients:
		if p != pid:
			rpc_id(p, "select_weapon", pid, index)
	
	# update own puppet
	var p = get_puppet_player(pid)
	if p != null:
		p.hand.update_weapon(index)
	else:
		print("select weapon: puppet not instanced yet")
remote func emit_sound(pid, sound_name):
	# tell the clients
	for p in clients:
		if p != pid:
			rpc_id(p, "play_sound", pid, sound_name)
	
	# play on own puppet
	var p = get_puppet_player(pid)
	if p != null:
		p.play_sound(sound_name)
	else:
		print("emit sound: puppet not instanced yet")
# <- Player called -

# - InGame Called ->
func player_hit_player(pid1, pid2, d, bodypart):
	# p1 hit p2 for 'dmg' in the 'bodypart'
	var p1 = get_puppet_player(pid1)
	var p2 = get_puppet_player(pid2)
	var dmg = gm.player_hit_player(pid1, pid2, d, bodypart)
	#print(str(pid1) + " hit " + str(pid2) + " with " + str(dmg) + " damage!")
	if dmg > 0:
		# apply the damage to p2
		p2.get_damage(dmg)
		rpc_id(int(pid2), "get_damage", dmg)
		# tell p1 that he hit his target
		rpc_id(int(pid1), "hit_target", dmg)
		
		# check if p2 died
		if p2.health <= 0:
			player_died(pid1, pid2)
func player_died(pid1, pid2):
	if not players_invincible:
		var p1 = get_puppet_player(pid1)
		var p2 = get_puppet_player(pid2)
		
		# tell the gamemode
		gm.player_died(pid2)
		if pid1 == pid2:
			gm.player_killed_himself(pid1)
		else:
			gm.player_kill(pid1)
		
		# kill the player on the server
		p2.die()
		
		# update the killfeed
		hud.update_killfeed(Global.clients[pid1].nickname, Global.clients[pid2].nickname)
		
		# tell the clients that pid1 killed pid2
		for p in clients:
			rpc_id(p, "player_died", pid1, pid2)
		
		# if he didnt kill himself
		if pid1 != pid2:
			# tell p1 that he killed his target
			rpc_id(int(pid1), "killed_target", pid2)
# <- InGame Called -

# - Tickrate triggered? ->
func update_clients():
	# update this method for efficiency
	for pid in clients:
		# for every client, update every player
		var client = clients[pid]
		for otherid in players:
			var other = players[otherid]
			if otherid != client.id:
				var info = other
				rpc_id(client.id, "update_puppet_player", info)
# <- Tickrate triggered? -

# - Own functions ->
func update_puppet_players():
	for pid in players:
		var p = get_puppet_player(pid)
		if p != null:
			p.update(players[pid])
		else:
			# create new puppet player, because it doesnt exist yet
			var new_p = puppet_player.instance()
			players_nodes_parent.add_child(new_p)
			new_p.init(players[pid])
			new_p.update(players[pid])
func remove_player_puppet(pid):
	get_puppet_player(pid).queue_free()
# <- Own functions -

# - Help functions ->
func is_player(cid):
	for pid in players:
		if cid == pid:
			return true
	return false
func call_rpc(method, argument):
	# to call rpc on all players in game (also spectators)
	for pid in clients:
		rpc_id(pid, method, argument)
func get_puppet_player(pid):
	var has_puppet = players_nodes_parent.has_node(str(pid))
	if has_puppet:
		return players_nodes_parent.get_node(str(pid))
	else:
		return null
	
	#var p = players_nodes_parent.get_node(str(pid))
	#if p != null:
	#	return p
	#else:
	#	# check if the player is even in the players dict
	#	if players.has(pid):
	#		# create new puppet player because it doesnt exist yet
	#		var new_p = puppet_player.instance()
	#		players_nodes_parent.add_child(new_p)
	#		new_p.init(players[pid])
	#		#print("create puppet: " + new_p.name)
	#		return new_p
	#	else:
	#		print("trying to get a puppet player which isnt event in the players dictionary")
	#return null
# <- Help functions -

# Tickrate Timer
func _on_TickrateTimer_timeout():
	update_puppet_players()
	update_clients()
