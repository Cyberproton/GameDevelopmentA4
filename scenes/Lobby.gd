extends Control


onready var ip_label = get_node("%IpLabel")
onready var player_count_label = get_node("%PlayerCount")
onready var overlay = get_node("%DialogOverlay")
onready var dialog = get_node("%Dialog")
remotesync var joined_players = []
remotesync var players_received_state = []
remotesync var ready_players = []
var initial_state: Array
var game = null


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	set_player_count(1)
	var ip_address = IP.get_local_addresses()[0]
	ip_label.text = "\nYour IP Address: " + ip_address
	if get_tree().is_network_server():
		joined_players.append(get_tree().get_network_unique_id())


func _player_connected(id):
	# Called on both clients and server when a peer connects. Send my info to it.
	if get_tree().is_network_server():
		print("Player ", id, " has successfully connected to the server")
		register_player(id)
	else:
		print("Successfully connected to the server")

	
func _player_disconnected(id):
	if get_tree().is_network_server():
		print("Player ", id, " has disconnected from the server")
		unregister_player(id)
	else:
		print("Disconnect from the server")
	rpc_id(id, "unregister_player")
	

func _connected_ok():
	pass # Only called on clients, not server. Will go unused; not useful here.
	

func _server_disconnected():
	# get_tree().change_scene("res://scenes/Multiplayer.tscn")
	popup_dialog()
	
	
func _connected_fail():
	get_tree().change_scene("res://scenes/Multiplayer.tscn")


puppet func set_joined_players(players):
	joined_players = players
	set_player_count(len(joined_players))


func register_player(id):
	joined_players.append(id)
	rpc("set_joined_players", joined_players)
	if len(joined_players) == Global.MAX_CLIENT:
		var state = get_initial_state()
		rpc("set_state", state)
		

func unregister_player(id):
	joined_players.erase(id)
	if joined_players.size() == 1:
		get_node("/root").remove_child(game)
		self.game = null
		get_tree().change_scene("res://scenes/Multiplayer.tscn")
	rpc("set_joined_players", joined_players)


func set_player_count(count: int):
	player_count_label.text = "Players Joined: " + String(count) + "/" + String(Global.MAX_CLIENT)


func get_initial_state():
	var state = [
		[   0,	2,	2,	2,	2, -1, -1, -1, -1],
		[	0,	0,	2,	2,	0,	0, -1, -1, -1],
		[	0,	0,	0,	0,	0,	0,	0, -1, -1],
		[	0,	0,	0,	0,	0,	0,	0,	0, -1],
		[   0,	0,	0,	0,	2,	2,	0,	0,	0],
		[  -1,  0,	0,	0,	0,	0,	0,	0,	0],
		[  -1, -1,  0,	0,	1,	1,	1,	0,	0],
		[  -1, -1, -1,  1,	1,	1,	1,	1,	1],
		[  -1, -1, -1, -1,	1,  1,  1,  1,  1],
	]
	var marble_to_players = {}
	for p in range(0, joined_players.size()):
		var player = joined_players[p]
		# for i in state.state.size():
		# 	var row = state.state[i]
		# 	for j in row.size():
		# 		if row[j] == p + 1:
		# 			row[j] = player
		marble_to_players[p + 1] = player 
	return [state, marble_to_players]
				

remotesync func set_state(state):
	self.initial_state = state
	rpc_id(1, "done_set_state")


remote func done_set_state():
	var who = get_tree().get_rpc_sender_id()
	players_received_state.append(who)
	if joined_players.size() - 1 == players_received_state.size():
		rpc("pre_configure_game")


remotesync func pre_configure_game():
	print("Pre-configure game ", get_tree().get_network_unique_id())
	get_tree().set_pause(true)
	var self_peer_id = get_tree().get_network_unique_id()

	# Load world
	var game = load("res://scenes/MultiplayerGame.tscn").instance()
	var players = []
	for i in joined_players.size():
		players.append(Player.new(joined_players[i], i, Global.PlayerMode.PLAYER))
	game.init(players, initial_state[0], initial_state[1])
	hide()
	get_node("/root").add_child(game)
	game.init_board()
	self.game = game

	# Tell server (server is always ID=1) that this peer is done pre-configuring.
	# The server can call get_tree().get_rpc_sender_id() to find out who said they were done.
	rpc_id(1, "done_preconfiguring")


remote func done_preconfiguring():
	print("Done-configure game ", get_tree().get_rpc_sender_id())
	var who = get_tree().get_rpc_sender_id()
	# Here are some checks you can do, for example
	assert(get_tree().is_network_server())
	assert(who in joined_players) # Exists
	assert(not who in ready_players) # Was not added yet

	ready_players.append(who)
	print("Client ", who, " is ready")
	print("Ready: ", len(ready_players), "/", joined_players.size())

	if ready_players.size() == joined_players.size() - 1:
		print("All players are ready")
		rpc("post_configure_game")


remotesync func post_configure_game():
	print("Post-configure game ", get_tree().get_network_unique_id())
	# Only the server is allowed to tell a client to unpause
	if 1 == get_tree().get_rpc_sender_id():
		get_tree().set_pause(false)
		# Game starts now!


func popup_dialog():
	get_tree().network_peer = null
	get_node("/root").remove_child(game)
	self.game = null
	overlay.show()
	dialog.popup()


func _on_Dialog_confirmed():
	get_tree().network_peer = null
	if game:
		get_node("/root").remove_child(game)
		self.game = null
	get_tree().change_scene("res://scenes/Multiplayer.tscn")


func _on_CancelButton_pressed():
	get_tree().network_peer = null
	get_tree().change_scene("res://scenes/Multiplayer.tscn")
