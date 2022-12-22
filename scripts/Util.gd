extends Node


var rng = RandomNumberGenerator.new()


func distance(first: Array, second: Array) -> float:
	return Vector2(first[1], first[0]).distance_to(Vector2(second[1], second[0]))


func plus_array_content(first: Array, second: Array) -> Array:
	assert(len(first) == len(second), "Two arrays must be same length")
	var res = []
	for i in len(first):
		res.append(first[i] + second[i])
	return res


func minus_array_content(first: Array, second: Array) -> Array:
	assert(len(first) == len(second), "Two arrays must be same length")
	var res = []
	for i in len(first):
		res.append(first[i] - second[i])
	return res


func negate_array_content(arr: Array) -> Array:
	var res = []
	for i in arr:
		res.append(-i)
	return res


func array_as_vector2(arr: Array) -> Vector2:
	return Vector2(arr[1], arr[0])


func is_down_right_direction(direction: Array) -> bool:
	return direction[0] >= 0 && direction[1] >= 0


func get_not_parallel_directions(direction: Array) -> Array:
	var res = []
	var first = -1
	var second = -1
	for i in len(Global.DIRECTIONS):
		if Global.DIRECTIONS[i] == direction:
			first = i
			break
	if first < 3:
		second = first + 3
	else:
		second = first - 3
	for i in len(Global.DIRECTIONS):
		if i == first || i == second:
			continue
		res.append(Global.DIRECTIONS[i])
	return res


func is_position_adjacent(first: Array, second: Array) -> bool:
	var y_diff = first[0] - second[0]
	var x_diff = first[1] - second[1]
	return [y_diff, x_diff] in Global.DIRECTIONS


func sort_positions_down_right(positions: Array) -> Array:
	var res = [] + positions
	res.sort_custom(self, "sort_positions_right")
	res.sort_custom(self, "sort_positions_down")
	return res


static func sort_positions_down(a, b):
	return a[0] < b[0]


static func sort_positions_right(a, b):
	return a[1] < b[1]


func move_line(line: Line, direction: Array) -> Line:
	var new_positions = []
	for position in line.positions:
		var new_position = Util.plus_array_content(position, direction)
		new_positions.append(new_position)
	return Line.new(new_positions)


func select_random_element(arr: Array):
	var i = rng.randi_range(0, len(arr) - 1)
	return arr[i]


func instantiate_node(node, parent):
	var instance = node.instance()
	parent.add_child(instance)
	return instance


func instantiate_node_at(node, parent, position: Vector2):
	var instance = instantiate_node(node, parent)
	instance.global_position = position
	return instance


func line_to_array(line: Line) -> Array:
	return line.to_array()


func line_from_array(arr: Array) -> Line:
	return Line.new(arr[0], arr[1])


func move_to_array(move: Move) -> Array:
	return move.to_array()


func move_from_array(arr: Array) -> Move:
	return Move.new(line_from_array(arr[0]), arr[1])
	