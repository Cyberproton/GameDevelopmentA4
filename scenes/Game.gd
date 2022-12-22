extends Node2D


onready var pause_button = get_node("%PauseButton")
onready var quit_confirmation = get_node("%ConfirmationDialog")
onready var game_over_dialog = get_node("%GameOverDialog")


func _ready():
	pass


func pause_game(pause = null):
	if pause == null:
		get_tree().paused = !get_tree().paused
	else: 
		get_tree().paused = pause
	if get_tree().paused:
		pause_button.text = ">"
	else:
		pause_button.text = "||"


func _on_PauseButton_pressed():
	pause_game()


func _on_QuitButton_pressed():
	pause_game(false)
	quit_confirmation.popup_centered()


func _on_ConfirmationDialog_confirmed():
	get_tree().change_scene("res://scenes/Main.tscn")


func _on_GameOverDialog_confirmed():
	get_tree().change_scene("res://scenes/Main.tscn")
