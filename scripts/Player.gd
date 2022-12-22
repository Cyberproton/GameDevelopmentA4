class_name Player


var id: int
var index: int
var player_mode: int


func _init(id: int, index: int, player_mode: int):
	self.id = id
	self.player_mode = player_mode
	self.index = index


func _to_string():
	return print({
		"id": id,
		"index": index,
		"player_mode": player_mode,
	})
