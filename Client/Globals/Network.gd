extends Node

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 31400

var menu = null

var peer
var nickname = ""
var local_id = 0

var current_state
enum STATE {
	disconnected = 0
	connected =     1,
	in_game =       2,
}

func _ready():
	current_state = STATE.disconnected
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("connected_to_server", self, "_connected_to_server")

func init_menu(m):
	menu = m

# - NETWORK SIGNALS ->
func _connection_failed():
	Global.message("connection failed")
	peer.close_connection()

func _connected_to_server():
	current_state = STATE.connected
	menu.connected()
	rpc_id(1, "connect_client", local_id, nickname)

remote func get_connected_clients(clients):
	Global.clients = clients

remote func other_player_connected(id, nickname):
	Global.clients[id] = {nickname = nickname}
	Global.clients[id].id = id
	
	if local_id != id:
		Global.message(str(nickname) + " connected to the server!")

remote func other_player_disconnected(id):
	var nickname = Global.clients[id].nickname
	Global.clients.erase(id)
	
	
	if current_state != STATE.in_game:
		Global.message(str(nickname) + " disconnected from the server!")
# <- NETWORK SIGNALS -


# - CLIENT CALLED ->
# connect to the server when clicked on JOIN in the menu
func connect_to_server(player_nickname, custom_ip = null):
	nickname = player_nickname
	
	var ip = DEFAULT_IP
	if custom_ip != null:
		ip = custom_ip
	
	Global.message("Trying to connect to " + str(ip) + ":" + str(DEFAULT_PORT) + "...")
	
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	local_id = get_tree().get_network_unique_id()

func disconnect_from_server():
	if peer != null and current_state != STATE.disconnected:
		if current_state != STATE.in_game:
			menu.disconnected()
		peer.close_connection()
		current_state = STATE.disconnected
	else:
		print("cant disconnect, because there is no connection ._.")
# <- CLIENT CALLED -



# - SERVER CALLED ->
remote func start_game_in(time):
	Global.message("Starting the game in " + str(time) + " seconds!")
remote func load_map(map):
	current_state = STATE.in_game
	# change the scene to the selected map
	get_tree().change_scene_to(Maps.scenes[map])
remote func game_canceled():
	current_state = STATE.connected
	Global.message("Game got cancelled by the server :(")
remote func close_server():
	current_state = STATE.disconnected
	get_tree().change_scene_to(Global.menu_scene)
	yield(get_tree().create_timer(0.5), "timeout")
	Global.message("Server has been closed!")
# <- SERVER CALLED -

