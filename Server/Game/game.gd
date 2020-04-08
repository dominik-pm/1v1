extends Node

var players_nodes_parent = null

onready var hud = $ServerHUD

# Game Mode
var gm

# all clients in game (players and spectators)
var clients = {}
# spectating the game
var spectators = {}
# playing in game
var players = {}

var players_ready = 0
var empty_player_info = { 
	id = 99, 
	position = Vector3(0,3,0), 
	rotation = Vector3(0,0,0), 
	headrotation = Vector3(0,0,0),
	animation = "idle"
}

var tickrate = 64
const END_TIME = 6

func _ready():
	var delta = 1.0/tickrate
	$TickrateTimer.wait_time = delta
	$TickrateTimer.autostart = false
	$TickrateTimer.one_shot = false

func init(pids):
	gm = get_parent().get_node("Gamemode")
	
	for id in pids:
		players[id] = empty_player_info.duplicate()
		players[id].id = id
		clients[id].id = id

# only initialize all players once everyone has loaded the map and is ready
remote func player_ready(pid):
	players_ready += 1
	if players_ready == players.size():
		gm.init_players(players)
	elif players_ready > players.size():
		client_connected(pid)

func client_connected(pid):
	# add the player to the spectators
	clients[pid].id = pid
	spectators[pid].id = pid
func client_disconnected(pid):
	clients.erase(pid)
	message(Global.clients[pid].nickname + " disconnected!")
	
	# check if he was a player/spectator
	if is_player(pid):
		# he is a player (remove puppet)
		remove_player_puppet(pid)
		# tell the clients to remove the puppet
		call_rpc("remove_player", pid)
	else:
		# he was a spectator, so remove him from the dictionary 
		spectators.erase(pid)

# - Gamemode called ->
# called for each player
func init_player(info):
	rpc_id(info.id, "init_self", info)
func gamemode_ready():
	$TickrateTimer.start()
	
	# get the player nodes
	players_nodes_parent = get_parent().get_node("PuppetPlayers")
	
	# tell every client to init the puppet players
	call_rpc("init_players", players)
	
	gm.start_game()
func display_status(msg):
	call_rpc("display_status", msg)
func respawn_player(pid, pos):
	var p = get_puppet_player(pid)
	p.respawn(pos)
	rpc_id(pid, "respawn_player", pos)
func remove_kills(pid, amt):
	rpc_id(pid, "remove_kills", amt)
func game_ended():
	#stun_players(true)
	yield(get_tree().create_timer(END_TIME), "timeout")
	Network.end_game()
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
	# locally, shoot a bullet from the right puppet
	# local
	var puppet_player = get_puppet_player(p_shot_id)
	puppet_player.shoot(dir, power, dmg, p_shot_id)
	
	# tell the other players, that this puppet shot
	for pid in players:
		if pid != p_shot_id:
			rpc_id(pid, "shoot_bullet_puppet", p_shot_id, dir, power)
	# also tell the spectators
	pass
remote func update_player(info):
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
	p.knifing(is_alternate)
remote func set_weapons(pid, weapons):
	# tell the clients
	for p in clients:
		if p != pid:
			rpc_id(p, "set_weapons", pid, weapons)
	
	# update own puppet
	var p = get_puppet_player(pid)
	p.hand.add_weapons(weapons)
remote func select_weapon(pid, index):
	# tell the clients
	for p in clients:
		if p != pid:
			rpc_id(p, "select_weapon", pid, index)
	
	# update own puppet
	var p = get_puppet_player(pid)
	p.hand.update_weapon(index)
remote func emit_sound(pid, sound_name):
	# tell the clients
	for p in clients:
		if p != pid:
			rpc_id(p, "play_sound", pid, sound_name)
	
	# play on own puppet
	var p = get_puppet_player(pid)
	p.play_sound(sound_name)
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
	var p1 = get_puppet_player(pid1)
	var p2 = get_puppet_player(pid2)
	
	# tell the gamemode that someone died
	gm.player_died(pid2)
	if pid1 != pid2:
		gm.player_kill(pid1)
	else:
		gm.player_killed_himself(pid1)
	
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
		# for every client, update every other client
		var client = players[pid]
		for otherid in players:
			var other = players[otherid]
			
			if otherid != client.id:
				var info = other
				rpc_id(client.id, "update_puppet_player", info)
# <- Tickrate triggered? -

# - Own functions ->
func update_puppet_players():
	for pid in players:
		var puppet_player = players_nodes_parent.get_node(str(pid))
		puppet_player.update(players[pid])
func message(msg):
	$CanvasLayer/Control/MessageText.text += "\n" + str(msg)
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
func get_puppet_player(id):
	return players_nodes_parent.get_node(str(id))
# <- Help functions -

# Tickrate Timer
func _on_TickrateTimer_timeout():
	update_puppet_players()
	update_clients()
