extends Node

class_name Gamemode

export var HEADSHOT_MULTIPLIER = 1.5
export var BODYSHOT_MULTIPLIER = 1.0
export var LIMBSHOT_MULTIPLIER = 0.8

var puppet_player = preload("res://Scenes/Player/PuppetPlayer.tscn")

var game = null
var spawns_points = null

var player_data = {}
#var player_nodes = null

func _ready():
	pass

# -- Game called -->
func init_players(players):
	# get the nodes
	game = get_parent().get_node("Game")
	spawns_points = get_parent().get_node("PlayerSpawns").get_children()
	
	# spawn players (instanciate puppet players)
	var puppet_players_parent = get_parent().get_node("PuppetPlayers")
	
	#print(players)
	for pid in players:
		var p = players[pid]
		player_data[pid] = {id = pid}
		init_data(pid)
		var new_p = puppet_player.instance()
		puppet_players_parent.add_child(new_p)
		new_p.init(p)
		game.init_player(p)
	
	#player_nodes = puppet_players_parent.get_children()
	
	# tell the game that we are ready
	game.gamemode_ready()

# - OVERWRITE IN CHILD CLASS ->
# to initialize the player_data with spawn_location, stats, etc
func init_data(pid):
	pass

func start_game():
	pass

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

func game_ended():
	game.game_ended()

func get_puppet_player(id):
	return game.players_nodes_parent.get_node(str(id))
