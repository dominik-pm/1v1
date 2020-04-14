extends Gamemode

const ROUNDS_TO_WIN = 5
const PRE_ROUND_TIME = 5
const POST_ROUND_TIME = 3

var i = 0
var game_is_finished = false # maybe different once posttime is added

var pre_round_timer

func _ready():
	pre_round_timer = Timer.new()
	pre_round_timer.wait_time = PRE_ROUND_TIME
	pre_round_timer.one_shot = true
	add_child(pre_round_timer)
	pre_round_timer.connect("timeout", self, "_on_pre_round_finished")

func init_data(pid):
	player_data[pid].alive = true
	player_data[pid].kills = 0
	player_data[pid].deaths = 0
	player_data[pid].spawn_location = spawns_points[i].global_transform.origin
	player_data[pid].round_wins = 0
	if i+1 < spawns_points.size():
		i = i + 1

func start_game():
	update_scoreboard()
	start_new_round()

func player_died(pid):
	player_data[pid].deaths += 1
	player_data[pid].alive = false
	
	update_scoreboard()
	game.kill_player(pid)
	
	game.players_invincible = true
	yield(get_tree().create_timer(POST_ROUND_TIME), "timeout")
	game.players_invincible = false
	
	if not game_is_finished:
		game.respawn_player(pid)
		start_new_round()

func player_killed_himself(pid):
	# give everyone else thats alive a point
	if players_alive() > 0:
		for id in player_data:
			if id != pid:
				if player_data[id].alive:
					player_data[id].round_wins += 1
					check_win(id)
	update_scoreboard()

func player_kill(pid):
	player_data[pid].kills += 1
	
	# start a new round if there is a winner, and the game is not finished
	if players_alive() <= 1 and !game_is_finished:
		player_data[pid].round_wins += 1
		check_win(pid)
		game.display_status(Global.clients[pid].nickname + " won this round!" + get_wins_string())

# do this always when chenging the current round wins of a player
func check_win(pid):
	# win statement
	if player_data[pid].round_wins >= ROUNDS_TO_WIN:
		print(Global.clients[pid].nickname + " won the 1v1!")
		game.display_status(Global.clients[pid].nickname + " won the 1v1!" + get_wins_string())
		game_is_finished = true
		
		# update statistics
		if Global.clients[pid].has("wins_1v1"):
			Global.clients[pid].wins_1v1 += 1
		else:
			Global.clients[pid].wins_1v1 = 1
		
		game_ended()

func start_new_round():
	pre_round_timer.start()
	game.start_timer(PRE_ROUND_TIME)
	game.display_status(get_wins_string())
	game.stun_players_for(PRE_ROUND_TIME)
	for pid in player_data:
		player_data[pid].alive = true
		game.reset_player(pid, player_data[pid].spawn_location)

func players_alive():
	var cnt = 0
	for pid in player_data:
		if player_data[pid].alive:
			cnt+=1
	return cnt

func get_wins_string():
	var s = "\n"
	for pid in player_data:
		s += Global.clients[pid].nickname
		s += ": " 
		s += str(player_data[pid].round_wins)
		s += "\n"
	return s

func _on_pre_round_finished():
	game.display_status("Round in Progress!" + get_wins_string())
