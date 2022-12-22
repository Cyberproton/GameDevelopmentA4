extends Control


func _on_HardButton_pressed():
	change_scene(GameSetup.Difficulty.IMPOSSIBLE)


func _on_MediumButton_pressed():
	change_scene(GameSetup.Difficulty.HARD)


func _on_EasyButton_pressed():
	change_scene(GameSetup.Difficulty.EASY)


func change_scene(difficulty: int):
	GameSetup.difficulty = difficulty
	get_tree().change_scene("res://scenes/Game.tscn")


func _on_BackButton_pressed():
	get_tree().change_scene("res://scenes/Main.tscn")
