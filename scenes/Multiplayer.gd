extends Control


onready var ip_label = get_node("%IpLabel")
onready var server_ip_input = get_node("%ServerIpInput")


func _ready():
	var ip_address = IP.get_local_addresses()[0]
	ip_label.text = "\nYour IP Address: " + ip_address
	server_ip_input.text = ip_address


func _on_JoinServerButton_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(server_ip_input.text, Global.SERVER_PORT)
	get_tree().network_peer = peer
	print("Your id is ", get_tree().get_network_unique_id())
	get_tree().change_scene("res://scenes/Lobby.tscn")


func _on_CreateServerButton_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(Global.SERVER_PORT, Global.MAX_CLIENT)
	get_tree().network_peer = peer	
	print("Your id is ", get_tree().get_network_unique_id())
	get_tree().change_scene("res://scenes/Lobby.tscn")


func _on_Back_pressed():
	get_tree().change_scene("res://scenes/Main.tscn")
