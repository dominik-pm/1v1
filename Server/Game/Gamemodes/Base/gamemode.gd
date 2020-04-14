extends Node

class_name Gamemode

# scores look like this
#var scores = {
#	"nitrogen": {
#		"kills": 10,
#		"deaths": 3
#	}
#}
var scores = {}

export var HEADSHOT_MULTIPLIER = 2.0
export var BODYSHOT_MULTIPLIER = 1.0
export var LIMBSHOT_MULTIPLIER = 0.8

var game = null
var spawns_points = null

var player_data = {}
#var player_nodes = null

func _ready():
	# get some nodes
	game = get_parent().get_node("Game")
	spawns_points = get_parent().get_node("PlayerSpawns").get_children()

# -- Game called -->
# initialize all players that are playing in this round
func init_player(pid):
	# init the player_data dictionary (for gamemode stuff like: kills, round_wins, ...)
	player_data[pid] = {id = pid}
	player_data[pid].kills = 0
	player_data[pid].deaths = 0
	init_data(pid)
	
	# init the scores dictionary
	scores[Global.clients[pid].nickname] = {kills=0, deaths=0}

func player_disconnected(pid):
	player_data.erase(pid)

# - OVERWRITE IN CHILD CLASS ->
# to initialize the player_data with spawn_location, stats, etc
func init_data(pid):
	pass

func start_game():
	update_scoreboard()

func player_died(pid):
	pass

func player_kill(pid):
	pass

func player_killed_himself(pid):
	pass
# <- OVERWRITE IN CHILD CLASS -

# - probably doesn't have to be overwritten ->
# returns the damage to apply
func player_hit_player(pid1, pid2, dmg, bodypart):
	# p1 hit p2's 'bodypart' with basedamage 'dmg'
	var d = dmg
	if bodypart == "head":
		d *= HEADSHOT_MULTIPLIER
	elif bodypart == "body":
		d *= BODYSHOT_MULTIPLIER
	elif bodypart == "limb":
		d *= LIMBSHOT_MULTIPLIER
	return d
# <- probably doesn't have to be overwritten -

# <-- Game called --

func update_scoreboard():
	for pid in player_data:
		scores[Global.clients[pid].nickname].kills = player_data[pid].kills
		scores[Global.clients[pid].nickname].deaths = player_data[pid].deaths
	game.update_scoreboard(scores)

func game_ended():
	game.game_ended()

func get_puppet_player(id):
	return game.players_nodes_parent.get_node(str(id))
