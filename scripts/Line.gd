class_name Line


var positions := []
var orientation := []
var length := -1
var top_left_position := []
var bottom_right_position := []
var sort_positions: bool


func _init(positions: Array, sort_positions: bool = false):
	self.sort_positions = sort_positions
	if sort_positions:
		self.positions = Util.sort_positions_down_right(positions)
	else:
		self.positions = positions + []
	self.length = len(positions)
	if length > 0:
		self.top_left_position = self.positions.front()
		self.bottom_right_position = self.positions.back()
	if self.length > 1:
		var first = positions[0]
		var second = positions[1]
		if first[0] < second[0] || first[1] < second[1]:
			self.orientation = [second[0] - first[0], second[1] - first[1]]
		else:
			self.orientation = [first[0] - second[0], first[1] - second[1]]


func _to_string():
	return String({
		"positions": positions,
		"orientation": orientation,
	})


func to_array():
	return [
		positions, 
		sort_positions,
	]
