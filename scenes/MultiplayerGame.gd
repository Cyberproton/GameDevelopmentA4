extends Node2D

onready var quit_confirmation = get_node("%ConfirmationDialog")


func _ready():
	pass


func _on_QuitButton_pressed():
	quit_confirmation.popup_centered()


func _on_ConfirmationDialog_confirmed():
	get_tree().change_scene("res://scenes/Multiplayer.tscn")
	get_tree().network_peer = null
	get_node("/root").remove_child(self)


onready var board = $Board
var players: Array
var initial_state: Array
var marble_to_players: Dictionary


func init(players, initial_state, marble_to_players):
	print("Initialize game")
	print(initial_state)
	self.players = players
	self.initial_state = initial_state
	print(self.initial_state)
	self.marble_to_players = marble_to_players


func init_board():
	board.init(players, initial_state, marble_to_players)



func _on_GameOverDialog_confirmed():
	get_tree().change_scene("res://scenes/Multiplayer.tscn")
	get_tree().network_peer = null
	get_node("/root").remove_child(self)
