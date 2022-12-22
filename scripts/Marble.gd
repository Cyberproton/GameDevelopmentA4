class_name Marble


var position: Array
var marble: int


func _init(position: Array, marble: int):
	self.position = position + []
	self.marble = marble


func _to_string():
	return String(marble)
