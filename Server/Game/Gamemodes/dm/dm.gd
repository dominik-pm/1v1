extends Gamemode

const ROUND_TIME = 30 # (seconds)
var timer
var leader_pid = null

func _ready():
	timer = Timer.new()
	timer.wait_time = ROUND_TIME
	timer.autostart = false
	timer.one_shot = true
	timer.connect("timeout", self, "_on_Roundtime_ended")
	add_child(timer)
	timer.start()

# dont need additional data
#func init_data(pid):
#	pass

func start_game():
	update_scoreboard()
	game.start_timer(ROUND_TIME)
	for pid in player_data:
		game.reset_player(pid, get_random_spawn_loc())

func player_died(pid):
	player_data[pid].deaths += 1
	game.reset_player(pid, get_random_spawn_loc())

func player_kill(pid):
	player_data[pid].kills += 1
	update_leaderboard()
	update_scoreboard()
func player_killed_himself(pid):
	player_data[pid].kills -= 1
	update_leaderboard()
	update_scoreboard()


func _on_Roundtime_ended():
	# check if there is a winner
	if Global.clients.has(leader_pid):
		game.display_status("Game ended: " + Global.clients[leader_pid].nickname + " won!")
	
		# update statistics
		if Global.clients[leader_pid].has("wins_deathmatch"):
			Global.clients[leader_pid].wins_deathmatch += 1
		else:
			Global.clients[leader_pid].wins_deathmatch = 1
	else:
		game.display_status("Game ended, nobody won :(")
	
	# call game ended
	game_ended()

func update_leaderboard():
	# get the new/current leader
	var current_max_kills = 0
	var cur_leader_pid = null
	for id in player_data:
		if player_data[id].kills > current_max_kills:
			cur_leader_pid = id
			current_max_kills = player_data[id].kills
	
	# check if there is current a leader
	if cur_leader_pid != null:
		# check if there even is a global leader
		if leader_pid == null:
			# there is no leader -> set the new leader as global leader
			leader_pid = cur_leader_pid
			game.display_status("Current Leader: " + Global.clients[leader_pid].nickname + " with " + str(player_data[leader_pid].kills) + " kills!")
		# check if the current leader is the new kill leader
		elif player_data[cur_leader_pid].kills > player_data[leader_pid].kills:
			# the current leader is different to the global leader -> set the new leader as global leader
			leader_pid = cur_leader_pid
	
	# update leaderboard
	if leader_pid != null:
		game.display_status("Current Leader: " + Global.clients[leader_pid].nickname + " with " + str(player_data[leader_pid].kills) + " kills!")

func get_random_spawn_loc():
	randomize()
	return spawns_points[int(rand_range(0, spawns_points.size()))].global_transform.origin
