extends Node

var player_id
var player = preload("res://Scenes/player/Player.tscn")
var puppet_player = preload("res://Scenes/player/PuppetPlayer/PuppetPlayer.tscn")
var puppet_players = {}
var puppet_nodes_parent = null

var tickrate = 64

func _ready():
	$TickrateTimer.wait_time = 1.0/tickrate
	$TickrateTimer.autostart = false
	$TickrateTimer.one_shot = false
	
	# tell the server that we are ready
	rpc_id(1, "player_ready", Network.local_id)

# - Tell the Server ->
func update_self():
	rpc_unreliable_id(1, "update_player", player.data)

func shoot(dir, power, dmg):
	rpc_id(1, "shoot_bullet", player_id, dir, power, dmg)
func knife(is_alternate):
	rpc_id(1, "knife", player_id, is_alternate)
func init_weapons(weapons):
	rpc_id(1, "set_weapons", player_id, weapons)
func switch_weapon(index):
	rpc_id(1, "select_weapon", player_id, index)
func emit_sound(sound_name):
	rpc_id(1, "emit_sound", player_id, sound_name)
# <- Tell the Server -

# - Server called ->
# to everyone
remote func knifing(pid, is_alternate):
	var p = get_puppet_player(pid)
	p.knifing(is_alternate)
remote func set_weapons(pid, weapons):
	var p = get_puppet_player(pid)
	p.hand.add_weapons(weapons)
remote func select_weapon(pid, index):
	var p = get_puppet_player(pid)
	p.hand.update_weapon(index)
remote func play_sound(pid, sound_name):
	var p = get_puppet_player(pid)
	p.play_sound(sound_name)
remote func remove_player(pid):
	puppet_players.erase(pid)
	get_puppet_player(pid).queue_free()

# init/puppets
remote func init_self(info):
	player_id = info.id
	player = player.instance()
	get_parent().add_child(player)
	player.init(info)
	$TickrateTimer.start()
remote func init_players(players):
	# spawn players (instanciate puppet players)
	puppet_nodes_parent = get_parent().get_node("PuppetPlayers")
	for pid in players:
		var p = players[pid]
		# only init other players
		if pid != player_id:
			var new_p = puppet_player.instance()
			puppet_nodes_parent.add_child(new_p)
			new_p.init(p)
remote func update_puppet_player(info):
	puppet_players[info.id] = info
	get_puppet_player(info.id).update(info)
remote func shoot_bullet_puppet(pid, dir, power):
	get_puppet_player(pid).shoot(dir, power)

# to this player
remote func get_damage(dmg):
	player.get_damage(dmg)
remote func player_died(pid_killer, pid_died):
	var killer_name = Global.clients[pid_killer].nickname
	var victim_name = Global.clients[pid_died].nickname
	
	# show in killfeed
	player.update_killfeed(killer_name, victim_name)
	
	print("updating killfeed")
	
	if pid_died == player_id:
		player.die()
	else:
		# otherplayerdied
		# hide the playermodel? (probably, if queuing free, it would have to be instanced again)
		pass
remote func remove_kills(amt):
	player.remove_kills(amt)
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
remote func display_status(msg):
	player.display_status(msg)
# <- Server called -

func get_puppet_player(id):
	return puppet_nodes_parent.get_node(str(id))

func _on_TickrateTimer_timeout():
	update_self()
