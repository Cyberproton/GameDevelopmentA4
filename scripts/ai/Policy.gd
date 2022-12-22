class_name Policy


static func random(state: State, player) -> Move:
	var moves = state.all_player_line_moves(player)
	var pick = randi() % moves.size()
	return moves[pick]


const MIN = 1
const MAX = 2


static func minimax(state, player, alpha, beta, depth = -1) -> Array:
	var score = -INF
	if player == MIN: 
		score = INF
	var best_move = null

	var opponent = MAX
	if player == MAX:
		opponent = MIN

	if state.is_player_win(opponent):
		return [score, null]
	elif depth == 0:
		return [eval(state), null]

	var moves = state.all_player_line_moves(player)

	if player == MAX:
		for move in moves:
			var next_state = State.new(state.state)
			next_state.move_by_move(move)
			var res = minimax(next_state, opponent, alpha, beta, depth - 1)
			var value = res[0]
			if value > score:
				score = value 
				best_move = move
			alpha = max(alpha, value)
			if alpha >= beta:
				break
	else:
		for move in moves:
			var next_state = State.new(state.state)
			next_state.move_by_move(move)
			var res = minimax(next_state, opponent, alpha, beta, depth - 1)
			var value = res[0]
			if value < score:
				score = value 
				best_move = move
			beta = min(beta, value)
			if alpha >= beta:
				break
			
	return [score, best_move]

		

static func eval(state: State):
	var center_proximity = state.center_proximity(MIN) - state.center_proximity(MAX)
	
	var cohesion = 0
	if abs(center_proximity) > 2:
		cohesion = state.marble_groups(MIN).size() - state.marble_groups(MAX).size()

	var marbles = 0
	if abs(center_proximity) < 1.8:
		marbles = len(state.player_marbles(MAX)) - len(state.player_marbles(1))
	return center_proximity + marbles + cohesion