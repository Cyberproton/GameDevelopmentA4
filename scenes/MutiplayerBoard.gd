extends Node2D

const H_OFFSET = -32
const V_OFFSET = 32

onready var player_turn_label = get_node("%PlayerTurnLabel")
onready var timer_label = get_node("%TimerLabel")
onready var player_1_score = get_node("%Player1Score")
onready var player_2_score = get_node("%Player2Score")
onready var game_over_dialog = get_node("%GameOverDialog")

var preload_marble = preload("res://entities/Marble.tscn")
var state: State
var you: int
var players: Array
remotesync var current_player: int
remotesync var current_player_index := 0
var selected_line: Line
var marbles := {}
var player_marbles := {}
var marble_players := {}

var elapsed_time: float = 0

var player_1_marbles: int
var player_2_marbles: int


func init(players, initial_state, marble_players):
	print("Initialize board")
	self.state = State.new(initial_state)
	self.you = get_tree().get_network_unique_id()
	self.players = players + []
	self.current_player = 1
	self.current_player_index = 0
	self.marble_players = marble_players
	for key in marble_players:
		var value = marble_players[key]
		player_marbles[value] = key

	player_1_marbles = state.player_marbles(1).size()
	player_2_marbles = state.player_marbles(2).size()
	

	position = get_viewport_rect().size / 2 - Vector2(
		Global.BOARD_SIZE[1] / 2 * Global.MARBLE_SIZE, 
		Global.BOARD_SIZE[0] / 2 * Global.MARBLE_SIZE
	)
	var rows = len(state.state)
	var mid = rows / 2

	for i in range(0, mid):
		var row = state.state[i]
		var dist = mid - i
		var offset = dist * Global.MARBLE_SIZE / 2
		for j in range(0, len(row)):
			var col = row[j]
			if col < 0:
				continue
			var marble = preload_marble.instance()
			marble.position = Vector2(offset + j * Global.MARBLE_SIZE + H_OFFSET, i * Global.MARBLE_SIZE + V_OFFSET)
			marble.grid_position = [i, j]
			marble.marble = col
			marble.connect("player_select_marble", self, "_on_player_select_marble")
			add_child(marble)
			set_marble_id([i, j], marble.get_instance_id())
	for j in range(0, 9):
		var col = state.state[mid][j]
		if col < 0:
			continue
		var marble = preload_marble.instance()
		marble.position = Vector2(j * Global.MARBLE_SIZE + H_OFFSET, mid * Global.MARBLE_SIZE + V_OFFSET)
		marble.grid_position = [mid, j]
		marble.marble = col
		set_marble_id([mid, j], marble.get_instance_id())
		marble.connect("player_select_marble", self, "_on_player_select_marble")
		add_child(marble)
	for i in range(mid + 1, rows):
		var row = state.state[i]
		var dist = i - mid
		var offset = dist * -Global.MARBLE_SIZE / 2
		for j in range(0, len(row)):
			var col = row[j]
			if col < 0:
				continue
			var marble = preload_marble.instance()
			marble.position = Vector2(offset + j * Global.MARBLE_SIZE + H_OFFSET, i * Global.MARBLE_SIZE + V_OFFSET)
			marble.grid_position = [i, j]
			marble.marble = col 
			set_marble_id([i, j], marble.get_instance_id())
			marble.connect("player_select_marble", self, "_on_player_select_marble")
			add_child(marble)
	set_player_turn_label(get_player_marble(current_player))
	update_score()
	print("Player ", current_player, "'s turn")


func _process(delta: float) -> void:
	elapsed_time += delta
	var minutes := elapsed_time / 60
	var seconds := fmod(elapsed_time, 60)
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	# if threadDone:
	# 	update_marbles()
	# 	rotate_next_player()
	# 	threadDone = false


func _input(event):
	if event is InputEventKey and event.pressed:
		var direction = Global.CONTROL_DIRECTIONS.get(event.scancode)
		if direction == null:
			return
		if selected_line == null:
			return
		if you != current_player:
			return
		rpc("move_by_client", Move.new(selected_line, direction).to_array())


func update_marbles():
	for i in len(state.state):
		var row = state.state[i]
		for j in len(row):
			var marble = row[j]
			if marble < 0:
				continue
			var marble_instance = get_marble_instance([i, j])
			marble_instance.marble = marble
		

remotesync func move_by_client(move: Array):
	print("Client ", String(get_tree().get_rpc_sender_id()), " request a move: ", move)
	var who = get_tree().get_rpc_sender_id()
	assert(current_player == who, "Not player " + String(who) + " turn")
	return move_by_player(current_player, Util.move_from_array(move))


func move_by_player(player: int, move: Move) -> bool:
	if player != current_player:
		assert(false, "Not player turn")
	var selected_line = move.line
	var direction = move.direction
	print("Player ", current_player, " move line ", selected_line.positions, " in direction ", direction)
	
	if !state.is_valid_move(get_current_player_marble(), selected_line, direction):
		return false
	state.move(selected_line, direction)

	selected_line = Util.move_line(selected_line, direction)
	# update_marbles()
	update_marbles()
	# for position in selected_line.positions:
	# 	get_marble_instance(position).selected = true
	rotate_next_player()

	return true


func move_by_ai(move: Move):
	var selected_line = move.line
	var direction = move.direction
	print("Player ", current_player, " move line ", selected_line.positions, " in direction ", direction)
	if !state.is_valid_move(current_player, selected_line, direction):
		assert(false, "Invalid move")
	state.move(selected_line, direction)
	update_marbles()
	rotate_next_player()


func _on_player_select_marble(marble, grid_position):
	if you != current_player:
		return
	if get_marble_player(marble) != current_player: 
		return
	var node = get_marble_instance(grid_position)
	var positions = []
	var select = !node.selected
	if select:
		if selected_line && selected_line.length >= Global.MAX_MARBLES_PER_LINE:
			return
		if selected_line:
			positions = selected_line.positions
		var line = Line.new(positions + [grid_position], true)
		if !state.is_valid_line(line):
			return
		selected_line = line
		node.selected = true
	else:
		positions = selected_line.positions
		positions.erase(node.grid_position)
		node.selected = false
		var line = Line.new(positions, true)
		if !state.is_valid_line(line):
			for pos in line.positions:
				get_marble_instance(pos).selected = false
			selected_line = null
			return
		selected_line = line
			

func get_marble_id(position: Array) -> int:
	if !marbles.has(position[0]):
		return -1
	var row = marbles[position[0]]
	if !row.has(position[1]):
		return -1
	return row[position[1]]


func get_marble_instance(position: Array):
	var id = get_marble_id(position)
	return instance_from_id(id)


func set_marble_id(position: Array, id: int) -> void:
	if !marbles.has(position[0]):
		marbles[position[0]] = {}
	var row = marbles[position[0]]
	row[position[1]] = id


func rotate_next_player() -> void:
	var marble = get_player_marble(current_player)
	if (state.is_player_win(marble)):
		print("Player ", current_player, " wins")
		game_over_dialog.dialog_text = "Player " + String(get_player_marble(current_player)) + " wins"
		game_over_dialog.popup()
	var next = (current_player_index + 1) % len(players)
	#current_player_index = next
	#current_player = players[next].id
	rset("current_player_index", next)
	rset("current_player", players[next].id)
	unselect_selected_line()
	# if player_modes[current_player_index] == Global.PlayerMode.AI:
	# 	var move = Policy.minimax(state, current_player, -INF, INF, 4)
	# 	move_by_ai(move[1])
	set_player_turn_label(get_player_marble(current_player))
	update_score()
	print("Player ", current_player, "'s turn")


func unselect_selected_line() -> void:
	if selected_line == null:
		return
	var positions = selected_line.positions
	for position in positions:
		get_marble_instance(position).selected = false
	selected_line = null


func get_current_player():
	return players[current_player]


func get_current_player_marble():
	return player_marbles[current_player]


func get_player_marble(player):
	if !player_marbles.has(player):
		return -1
	return player_marbles[player]


func get_marble_player(marble):
	if !marble_players.has(marble):
		return -1
	return marble_players[marble]


func set_player_turn_label(player):
	var color = Global.MARBLE_COLORS[player]
	var prefix = "Player"
	player_turn_label.text = prefix + " " + String(player) + "'s Turn"
	player_turn_label.add_color_override("font_color", color)


func update_score():
	player_1_score.text = "%02d" % (player_2_marbles - state.player_marbles(2).size())
	player_1_score.add_color_override("font_color", Global.MARBLE_COLORS[1])
	player_2_score.text = "%02d" % (player_1_marbles - state.player_marbles(1).size())
	player_2_score.add_color_override("font_color", Global.MARBLE_COLORS[2])
