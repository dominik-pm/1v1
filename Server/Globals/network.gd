extends Node

var player_ids = []

var autoclose = false
var peer = null

var current_state
enum STATE {
	offline =    0,
	online =     1,
	in_game =    2,
	game_ended = 3
}

# default settings
var SETTINGS = {
	"DEFAULT_IP": '91.114.179.164',
	"DEFAULT_PORT": 31400,
	"TIME_TO_START": 1,
	"MAX_PLAYERS": 3,
	"MAP": 0,
	"GAMEMODE": 0
}

var menu = null

func _ready():
	current_state = STATE.offline
	
	get_tree().set_auto_accept_quit(false)
	
	initialize()
	
	get_tree().connect('network_peer_connected', self, '_on_client_connected')
	get_tree().connect('network_peer_disconnected', self, '_on_client_disconnected')

func init_menu(m):
	menu = m

func initialize():
	peer = null
	player_ids = []

# -- SIGNALS -->
func _on_client_connected(id):
	pass # maybe this function is useless bc of the next one

remote func connect_client(id, nickname):
	player_ids.push_back(id)
	
	Global.clients[id] = {nickname = nickname}
	Global.clients[id].id = id
	
	if current_state == STATE.in_game:
		var game = get_node(Global.game_path)
		if game != null:
			rpc_id(id, "load_map", SETTINGS["MAP"])
	
	rpc_id(id, "get_connected_clients", Global.clients)
	rpc("other_player_connected", id, nickname)
	Global.message(str(nickname) + "("+str(id)+") connected!")

func _on_client_disconnected(id):
	var nickname = Global.clients[id].nickname
	rpc("other_player_disconnected", id)
	Global.message(str(nickname) + " ("+str(id)+") disconnected!")
	
	var game = get_node(Global.game_path)
	if game != null:
		game.client_disconnected(id)
	
	Global.clients.erase(id)
	player_ids.erase(id)
	if player_ids.size() == 0 and autoclose:
		close_server()
# <-- SIGNALS --

# -- SERVER FUNCTIONS -->
# setup the server when clicked on create in the menu
func create_server():
	peer = NetworkedMultiplayerENet.new()
	#peer.set_bind_ip(SETTINGS["DEFAULT_IP"])
	var check = peer.create_server(SETTINGS["DEFAULT_PORT"], SETTINGS["MAX_PLAYERS"])
	
	# check if it worked (does not work if server already running)
	if check == OK:
		get_tree().set_network_peer(peer)
		Global.message("Server created on "+SETTINGS["DEFAULT_IP"]+":"+str(SETTINGS["DEFAULT_PORT"])+"!")
		menu.server_created()
		current_state = STATE.online
	else:
		peer = null
		Global.message("Could not create server. There already is an open connection!")

func close_server():
	if peer != null:
		if get_tree().current_scene.name != "MainMenu":
			get_tree().change_scene_to(Global.menu_scene)
		
		rpc("close_server")
		current_state = STATE.offline
		Global.message("Closing the server...")
		yield(get_tree().create_timer(0.5), "timeout")
		peer.close_connection()
		yield(get_tree().create_timer(0.5), "timeout")
		initialize()
		menu.server_closed()
	else:
		print("not running")

func quit():
	close_server()
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().quit()

func start_game():
	if peer != null:
		if player_ids.size() > 0:
			# tell the client that the game is starting
			for pid in player_ids:
				rpc_id(pid, "start_game_in", SETTINGS["TIME_TO_START"])
			
			# change the scene to the selected map
			get_tree().change_scene_to(Maps.scenes[SETTINGS["MAP"]])
			
			# change state
			current_state = STATE.in_game
			
			# after the timeout, tell the clients to load the map
			yield(get_tree().create_timer(SETTINGS["TIME_TO_START"]), "timeout")
			for pid in player_ids:
				rpc_id(pid, "load_map", SETTINGS["MAP"])
		else:
			Global.message("No Players connected!")
	else:
		Global.message("Server not running!")

func game_cancelled():
	rpc("game_cancelled")

# end the progress in game
#func end_game():
#	rpc('close_game')
#	Global.message("game ended")
#	yield(get_tree().create_timer(0.5), "timeout")

#func get_status():
#	var status = "no status defined for this scenario"
#	
#	if current_state == STATE.waitingforplayers:
#		status = "Waiting for players..."
#	elif current_state == STATE.countdownstarted:
#		status = "Game is starting in " + str(int(startgame_timer.time_left)) + " seconds!"
#	elif current_state == STATE.gamestarted:
#		status = "Game in progress. Waiting for it to finish..."
#	
#	return status

# <-- SERVER FUNCTIONS --


# -- CLIENT CALLED -->

"""
remote func request_game_status(request_from_id):
	var status = get_status()
	rpc_id(request_from_id, 'response_game_status', status)

# a new player tells his info
remote func _send_new_player_info(id, info):
	players[id] = info

# a player is requesting another players info
remote func _request_player_info(request_from_id, player_id):
	print(str(request_from_id) +" request to get player info from "+str(player_id))
	# send the player info to the player that requested it
	rpc_id(request_from_id, '_receive_player_info', player_id, players[player_id])

# a players updates his info
remote func _update_player_info(id, info):
	players[id] = info

remote func left_game(id):
	players_in_game.erase(id)
"""
# <-- CLIENT CALLED --
