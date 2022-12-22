extends Control


func _on_MultiplayerButton_pressed():
	get_tree().change_scene("res://scenes/Multiplayer.tscn")


func _on_PvPButton_pressed():
	get_tree().change_scene("res://scenes/Game.tscn")


func _on_PvCButton_pressed():
	get_tree().change_scene("res://scenes/Difficulty.tscn")
