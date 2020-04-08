extends Gamemode

const ROUNDS_TO_WIN = 5
const PRE_ROUND_TIME = 5
const POST_ROUND_TIME = 3
var post_round = false

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
	player_data[pid].spawn_location = spawns_points[i].global_transform.origin
	player_data[pid].round_wins = 0
	if i+1 < spawns_points.size():
		i = i + 1

func start_game():
	start_new_round()

func player_died(pid):
	# somehow do something with postround so that nobody can die (maybe)
	#post_round = true
	#yield(get_tree().create_timer(POST_ROUND_TIME), "timeout")
	#post_round = false
	if not game_is_finished:
		start_new_round()

func player_kill(pid):
	player_data[pid].round_wins += 1
	print("1v1.gd test round wins: " + str(player_data[pid].round_wins))
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

func player_killed_himself(pid):
	# give everyone else a point
	for id in player_data:
		if id != pid:
			player_data[pid].round_wins += 1

func start_new_round():
	pre_round_timer.start()
	game.display_status("Starting the round in " + str(PRE_ROUND_TIME) + " seconds!" + get_wins_string())
	game.stun_players_for(PRE_ROUND_TIME)
	for pid in player_data:
		game.respawn_player(pid, player_data[pid].spawn_location)

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
