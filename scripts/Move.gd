class_name Move


var line: Line
var direction: Array
var length: int


func _init(line: Line, direction: Array):
	self.line = line
	self.direction = direction + []
	self.length = line.length


func _to_string():
	return print({
		"line": line.positions,
		"direction": direction,
	})


func to_array():
	return [
		line.to_array(),
		direction,
	]
