extends Node

const DEFAULT_IP = '10.0.0.8'
const DEFAULT_PORT = 31400

var players = { }
var self_data = { name = '', position = Vector3(0,3,0), rotation = Vector3(0,0,0), headrotation = Vector3(0,0,0), health = 0 }

var peer
var local_id = 0

# description (outdated):


# -- CUSTOMIZE -->

# update our position on the server
func update_self():
	rpc_unreliable("_update_player_info", local_id, self_data)


# <-- CUSTOMIZE --


func _ready():
	get_tree().connect("connection_failed", self, '_connection_failed')
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')


# - NETWORK SIGNALS ->
func _connection_failed():
	print("connection failed")
	peer.close_connection()

# create a player and tell the server our info
func _connected_to_server():
	print("connected to server!")

# request the new players info
func _on_player_connected(connected_player_id):
	if connected_player_id != local_id  and connected_player_id != 1:
		global.display_status(str(connected_player_id) + " connected!")
		#rpc_id(1, '_request_player_info', local_player_id, connected_player_id)

# remove disconnected player from the array
func _on_player_disconnected(id):
	global.display_status(str(id) + " disconnected!")
	players.erase(id)
# <- NETWORK SIGNALS -


# - CLIENT CALLED ->
# connect to the server when clicked on JOIN in the menu
func connect_to_server(player_nickname, custom_ip):
	self_data.name = player_nickname
	
	var ip = DEFAULT_IP
	if custom_ip != null:
		ip = custom_ip
	
	print("trying to connect to " + str(ip) + ":" + str(DEFAULT_PORT) + "...")
	
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	local_id = get_tree().get_network_unique_id()

func disconnect_from_server():
	if peer != null:
		print("disconnected")
		peer.close_connection()
	else:
		print("cant disconnect, because there is no connection ._.")
# <- CLIENT CALLED -



# - SERVER CALLED ->
"""
# start the lobby
remote func load_lobby():
	global.get_to_lobby()
	rpc_id(1, 'request_game_status', local_id)

# start the game
sync func start_game():
	global.get_to_game(local_id)

remote func close_game():
	global.get_to_menu()

# when the server closes
remote func close_server():
	global.get_to_menu()
	global.display_status("Server closed")
	disconnect_from_server()

# display game status
remote func response_game_status(msg):
	global.display_status(msg)

# update player info (response from request_player_info)
remote func _receive_player_info(id, info):
	players[id] = info
	global.update_player(id, info)

# update another players info
sync func _update_player_info(id, info):
	players[id] = info
	global.update_player(id, info)
"""
# <- SERVER CALLED -
