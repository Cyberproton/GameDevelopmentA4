class_name State


const EMPTY := 0
const INVALID := -1

var state := [
	[   2,	2,	2,	2,	2, -1, -1, -1, -1],
	[	2,	2,	2,	2,	2,	2, -1, -1, -1],
	[	0,	0,	2,	2,	2,	0,	0, -1, -1],
	[	0,	0,	0,	0,	0,	0,	0,	0, -1],
	[   0,	0,	0,	0,	2,	2,	0,	0,	0],
	[  -1,  0,	0,	0,	0,	0,	0,	0,	0],
	[  -1, -1,  0,	0,	1,	1,	1,	0,	0],
	[  -1, -1, -1,  1,	1,	1,	1,	1,	1],
	[  -1, -1, -1, -1,	1,  1,  1,  1,  1],
]

var center = [len(state) / 2, len(state[0]) / 2]


func _init(current_state: Array = []):
	if current_state != []: 
		var new_state = []
		for row in current_state:
			new_state.append(row + [])
		state = new_state


func set_marble(position: Array, marble: int) -> void:
	if !(position[0] in range(len(state))):
		return
	var row = state[position[0]]
	if !(position[1] in range(len(row))) || row[position[1]] < 0:
		return
	row[position[1]] = marble


func get_marble(position: Array) -> int:
	if !(position[0] in range(len(state))):
		return INVALID
	var row = state[position[0]]
	if !(position[1] in range(len(row))):
		return INVALID
	return row[position[1]]


func get_player_marbles(player: int) -> Array:
	var res = []
	for i in len(state):
		for j in len(state[i]):
			if state[i][j] != player:
				continue
			res.append([i, j])
	return res


func is_position_valid(position: Array) -> bool:
	if !(position[0] in range(len(state))):
		return false
	var row = state[position[0]]
	if !(position[1] in range(len(row))):
		return false
	return row[position[1]] > -1


func is_position_empty(position: Array) -> bool:
	if !(position[0] in range(len(state))):
		return false
	var row = state[position[0]]
	if !(position[1] in range(len(row))):
		return false
	return row[position[1]] == 0


func _to_string():
	return JSON.print(state);


##### Query functions


func player_marbles(player: int) -> Array:
	var res = []
	for i in len(state):
		for j in len(state[i]):
			var marble = state[i][j]
			if marble != player:
				continue
			res.append(Marble.new([i, j], marble))
	return res


func player_marble_positions(player: int) -> Array:
	var res = []
	for i in len(state):
		for j in len(state[i]):
			var marble = state[i][j]
			if marble != player:
				continue
			res.append([i, j])
	return res


func neighbors(position: Array) -> Array:
	var state = self
	var res = []
	var marble = state.get_marble(position)
	if marble == INVALID:
		return []
	for direction in Global.DIRECTIONS:
		var next_position = Util.plus_array_content(position, direction)
		var next_marble = state.get_marble(next_position)
		if next_marble < 1:
			continue
		res.append(Marble.new(next_position, next_marble))
	return res


func friendly_neighbors(position: Array) -> Array:
	var res = []
	var marble = get_marble(position)
	if marble == INVALID:
		return []
	for direction in Global.DIRECTIONS:
		var next_position = Util.plus_array_content(position, direction)
		var next_marble = get_marble(next_position)
		if next_marble != marble:
			continue
		res.append(Marble.new(next_position, next_marble))
	return res


func friendly_neighbor_positions(position: Array) -> Array:
	var res = []
	var marble = get_marble(position)
	if marble == INVALID:
		return []
	for direction in Global.DIRECTIONS:
		var next_position = Util.plus_array_content(position, direction)
		var next_marble = get_marble(next_position)
		if next_marble != marble:
			continue
		res.append(next_position)
	return res


func all_player_lines(player: int) -> Array:
	var lines = []
	var player_marbles = player_marbles(player)
	var checked_positions = []
	# Check marbles top-down left-right
	for marble in player_marbles:
		# Find line origins from marble position
		# Direction: DOWN, RIGHT
		for orientation in Global.ORIENTATIONS:
			var marble_position = marble.position
			var marble_lines = player_lines(player, marble_position, orientation)
			for marble_line in marble_lines:
				if marble_line.length == 1 && checked_positions.has(marble_line.positions[0]):
					continue
				lines.append(marble_line)
				checked_positions.append(marble_line.positions[0])
	return lines


func player_lines(player: int, marble_position: Array, direction: Array) -> Array:
	var state = self
	var lines = []
	var line = []
	var marbles = []
	var count = 0
	var next_position = marble_position
	var next_marble = state.get_marble(next_position)
	while next_marble == player && count < Global.MAX_MARBLES_PER_LINE:
		line.append(next_position)
		marbles.append(Marble.new(next_position, next_marble))
		next_position = Util.plus_array_content(next_position, direction)
		next_marble = state.get_marble(next_position)
		count += 1
		# For every possible line length
		lines.append(Line.new([] + line))
		#lines.append([] + line)
	return lines


func line(position: Array, direction: Array, max_length: int = -1) -> Line:
	var state = self
	var max_len = max_length
	if max_len < 0:
		max_len = Global.MAX_MARBLES_PER_LINE
	var line = []
	var marbles = []
	var next_position = position
	var next_marble = state.get_marble(next_position)
	var count = 0
	while next_marble > -1 && count < max_len:
		line.append(next_position)
		marbles.append(Marble.new(next_position, next_marble))
		next_position = Util.plus_array_content(next_position, direction)
		next_marble = state.get_marble(next_position)
		count += 1
	return Line.new(line)


func not_empty_line(position: Array, direction: Array, max_length: int = -1) -> Line:
	var state = self
	var max_len = max(max_length, Global.MAX_MARBLES_PER_LINE)
	var line = []
	var marbles = []
	var next_position = position
	var next_marble = state.get_marble(next_position)
	var count = 0
	while next_marble > 0 && count < max_len:
		line.append(next_position)
		marbles.append(Marble.new(next_position, next_marble))
		next_position = Util.plus_array_content(next_position, direction)
		next_marble = state.get_marble(next_position)
		count += 1
	return Line.new(line)


func is_valid_line(line: Line) -> bool:
	var positions = line.positions
	if len(positions) == 0:
		return false
	if len(positions) == 1:
		return true
	var first_position = positions.front()
	var first_position_vec = Util.array_as_vector2(first_position)
	if !is_position_valid(first_position):
		return false
	var direction = Util.minus_array_content(positions[1], first_position)
	var direction_vec = Util.array_as_vector2(direction)
	var prev_pos = first_position
	for i in range(1, len(positions)):
		var second_pos = positions[i]
		if !is_position_valid(second_pos):
			return false
		var second_pos_vec = Util.array_as_vector2(second_pos)
		if !Util.is_position_adjacent(prev_pos, second_pos):
			return false
		var second_dir = Util.minus_array_content(second_pos, first_position)
		var second_dir_vec = Util.array_as_vector2(second_dir)
		if direction_vec.cross(second_dir_vec) != 0:
			return false
		prev_pos = second_pos
	return true
		

func is_line_empty(line: Line) -> bool:
	for position in line.positions:
		var marble = get_marble(position)
		if marble == 0:
			continue
		return false
	return true


func marbles_in_line(line: Line) -> Array:
	var marbles = []
	for position in line.positions:
		var marble = get_marble(position)
		marbles.append(Marble.new(position, marble))
	return marbles


func all_player_line_moves(player: int) -> Array:
	var moves = []
	var lines = all_player_lines(player)
	for l in lines:
		for direction in Global.DIRECTIONS:
			# Move a single marble
			if l.length < 2:
				var position = l.positions[0]
				var next_position = Util.plus_array_content(position, direction)
				if !is_position_empty(next_position):
					continue
				moves.append(Move.new(l, direction))
				continue

			# Move a line of marbles
			var is_linear_movement = false
			if Util.array_as_vector2(direction).cross(Util.array_as_vector2(l.orientation)) == 0:
				is_linear_movement = true

			if is_linear_movement:
				var start = null
				if Util.is_down_right_direction(direction):
					start = Util.plus_array_content(l.bottom_right_position, direction)
				else:
					start = Util.plus_array_content(l.top_left_position, direction)

				var mirror = self.line(start, direction, l.length)
				if mirror.length == 0:
					continue
				var opponent_strength = 0
				var moveable = true
				
				for position in mirror.positions:
					var marble = get_marble(position)
					if marble == player:
						moveable = false
						break
					if marble == EMPTY:
						break
					opponent_strength += 1
				
				# Not enough strength
				if l.length <= opponent_strength || opponent_strength > Global.MAX_PUSH_STRENGTH:
					continue

				if !moveable:
					continue
				moves.append(Move.new(l, direction))
			else:
				var start = Util.plus_array_content(l.top_left_position, direction)
				var mirror = line(start, l.orientation, l.length)
				if l.length != mirror.length:
					continue
				if !is_line_empty(mirror):
					continue
				moves.append(Move.new(l, direction))
	return moves


func is_valid_move(player: int, l: Line, direction: Array) -> bool:
	# Move a single marble
	if l.length < 2:
		var position = l.positions[0]
		var next_position = Util.plus_array_content(position, direction)
		return is_position_empty(next_position)

	# Move a line of marbles
	var is_linear_movement = false
	if Util.array_as_vector2(direction).cross(Util.array_as_vector2(l.orientation)) == 0:
		is_linear_movement = true

	if is_linear_movement:
		var start = null
		if Util.is_down_right_direction(direction):
			start = Util.plus_array_content(l.bottom_right_position, direction)
		else:
			start = Util.plus_array_content(l.top_left_position, direction)
		var mirror = self.line(start, direction, l.length)
		if mirror.length == 0:
			return false
		var opponent_strength = 0
		for position in mirror.positions:
			var marble = get_marble(position)
			if marble == player:
				return false
			if marble == EMPTY:
				break
			opponent_strength += 1

		# Not enough strength
		if l.length <= opponent_strength || opponent_strength > Global.MAX_PUSH_STRENGTH:
			return false
		
		return true
	else:
		var start = Util.plus_array_content(l.top_left_position, direction)
		var mirror = line(start, l.orientation, l.length)
		if l.length != mirror.length:
			return false
		return is_line_empty(mirror)
			

func move(l: Line, direction: Array) -> void:
	# Move a single marble
	if l.length < 2:
		var position = l.positions[0]
		var marble = get_marble(position)
		var next_position = Util.plus_array_content(position, direction)
		set_marble(next_position, marble)
		set_marble(position, EMPTY)
		return

	# Move a line of marbles
	var is_linear_movement = false
	if Util.array_as_vector2(direction).cross(Util.array_as_vector2(l.orientation)) == 0:
		is_linear_movement = true

	# Move opponent marbles
	if is_linear_movement:
		var start = null
		if Util.is_down_right_direction(direction):
			start = Util.plus_array_content(l.bottom_right_position, direction)
		else:
			start = Util.plus_array_content(l.top_left_position, direction)

		var mirror = self.not_empty_line(start, direction, l.length)
		var mirror_marbles = marbles_in_line(mirror)
		for i in len(mirror.positions):
			var position = mirror.positions[i]
			var marble = mirror_marbles[i]
			var next_position = Util.plus_array_content(position, direction)
			set_marble(next_position, marble.marble)
	
	# Move player marbles
	# Clear old marbles
	var marbles = marbles_in_line(l)
	for position in l.positions:
		set_marble(position, EMPTY)

	# Set new marbles
	for i in len(l.positions):
		var position = l.positions[i]
		var marble = marbles[i]
		var next_position = Util.plus_array_content(position, direction)
		set_marble(next_position, marble.marble)


func move_by_move(move: Move) -> void:
	move(move.line, move.direction)


func center_proximity(player):
	var marbles = player_marbles(player)
	var dist = -INF
	for marble in marbles:
		if dist == -INF:
			dist = Util.distance(marble.position, center)
		else:
			dist += Util.distance(marble.position, center)
	return dist / marbles.size()


func marble_groups(player):
	var marbles = player_marble_positions(player)
	var groups = []
	var checked = []
	while marbles.size() > 0:
		var position = marbles.pop_back()
		if checked.has(position):
			continue
		var neighbors = friendly_neighbor_positions(position)
		var group = []
		while neighbors.size() > 0:
			var neighbor = neighbors.pop_back()
			if checked.has(neighbor):
				continue
			checked.append(neighbor)
			group.append(neighbor)
			var others = friendly_neighbor_positions(neighbor)
			for other in others:
				if checked.has(other):
					continue
				neighbors.append(other)
		groups.append(group)
	return groups


func is_player_win(player) -> bool:
	var next = -1
	if player == 1:
		next = 2
	else:
		next = 1
	print(len(player_marbles(next)))
	return len(player_marbles(next)) <= Global.GAME_OVER_MARBLES
