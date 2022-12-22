extends Node2D


const H_OFFSET = -32
const V_OFFSET = 32

onready var player_turn_label = get_node("%PlayerTurnLabel")
onready var timer_label = get_node("%TimerLabel")
onready var player_1_score = get_node("%Player1Score")
onready var player_2_score = get_node("%Player2Score")
onready var game_over_dialog = get_node("%GameOverDialog")

var preload_marble = preload("res://entities/Marble.tscn")
var state := State.new([
	[   0,	2,	2,	2,	2, -1, -1, -1, -1],
	[	0,	0,	2,	2,	0,	0, -1, -1, -1],
	[	0,	0,	0,	0,	0,	0,	0, -1, -1],
	[	0,	0,	0,	0,	0,	0,	0,	0, -1],
	[   0,	0,	0,	0,	2,	2,	0,	0,	0],
	[  -1,  0,	0,	0,	0,	0,	0,	0,	0],
	[  -1, -1,  0,	0,	1,	1,	1,	0,	0],
	[  -1, -1, -1,  1,	1,	1,	1,	1,	1],
	[  -1, -1, -1, -1,	1,  1,  1,  1,  1],
])
var players := [1, 2]
var current_player := 1
var current_player_index := 0
var player_modes := [Global.PlayerMode.PLAYER, Global.PlayerMode.AI]
var ai_policies := {
	2: Global.AIPolicy.MINIMAX,
}
var depth = 3
var selected_line: Line
var marbles := {}

var thread: Thread
var mutex: Mutex
var threadDone = false

var elapsed_time: float = 0

var player_1_marbles: int
var player_2_marbles: int


func _ready():
	thread = Thread.new()
	mutex = Mutex.new()

	# Setup game
	match GameSetup.difficulty:
		GameSetup.Difficulty.EASY:
			ai_policies = {
				2: Global.AIPolicy.RANDOM
			}
		GameSetup.Difficulty.HARD:
			ai_policies = {
				2: Global.AIPolicy.MINIMAX
			}
			depth = 2
		GameSetup.Difficulty.IMPOSSIBLE:
			ai_policies = {
				2: Global.AIPolicy.MINIMAX
			}
			depth = 3

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

	player_1_marbles = state.player_marbles(1).size()
	player_2_marbles = state.player_marbles(2).size()

	update_score()


func _process(delta: float) -> void:
	elapsed_time += delta
	var minutes := elapsed_time / 60
	var seconds := fmod(elapsed_time, 60)
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	if threadDone:
		update_marbles()
		rotate_next_player()
		threadDone = false



func _exit_tree():
	thread.wait_to_finish()


func update_marbles():
	mutex.lock()
	print("Update scene")
	for i in len(state.state):
		var row = state.state[i]
		for j in len(row):
			var marble = row[j]
			if marble < 0:
				continue
			get_marble_instance([i, j]).marble = marble
	
	mutex.unlock()



func _input(event):
	if event is InputEventKey and event.pressed:
		if player_modes[current_player_index] == Global.PlayerMode.AI:
			return
		var direction = Global.CONTROL_DIRECTIONS.get(event.scancode)
		if direction == null:
			return
		if selected_line == null:
			return
		var moveable = move_by_player(direction)
		if !moveable:
			return
		for position in selected_line.positions:
			get_marble_instance(position).selected = false
		selected_line = Util.move_line(selected_line, direction)
		update_marbles()
		for position in selected_line.positions:
			get_marble_instance(position).selected = true
		rotate_next_player()
		
		

func move_by_player(direction: Array) -> bool:
	mutex.lock()
	print("Player ", current_player, " move line ", selected_line.positions, " in direction ", direction)
	if !state.is_valid_move(current_player, selected_line, direction):
		mutex.unlock()
		return false
	state.move(selected_line, direction)
	mutex.unlock()
	return true


func move_by_ai(userdata):
	mutex.lock()
	print("Comp start thinking")
	var move = null
	if ai_policies.get(current_player) == Global.AIPolicy.MINIMAX:
		move = Policy.minimax(state, current_player, -INF, INF, depth)[1]
	else:
		move = Policy.random(state, current_player)
	print("Comp done thinking")
	var selected_line = move.line
	var direction = move.direction
	print("Player ", current_player, " move line ", selected_line.positions, " in direction ", direction)
	if !state.is_valid_move(current_player, selected_line, direction):
		assert(false, "Invalid move")
	state.move(selected_line, direction)
	mutex.unlock()
	thread.call_deferred("wait_to_finish")
	threadDone = true


func _on_player_select_marble(marble, grid_position):
	if marble != current_player: 
		return
	if player_modes[current_player_index] == Global.PlayerMode.AI:
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
	if (state.is_player_win(current_player)):
		print("Player ", current_player, " wins")
		game_over_dialog.popup()
	var next = (current_player_index + 1) % len(players)
	current_player_index = next
	current_player = players[next]

	set_player_turn_label(current_player)
	update_score()

	unselect_selected_line()

	elapsed_time = 0

	if player_modes[current_player_index] == Global.PlayerMode.AI:
		threadDone = false
		var status = thread.start(self, "move_by_ai")
		#move_by_ai(null)
	


func unselect_selected_line() -> void:
	if selected_line == null:
		return
	var positions = selected_line.positions
	for position in positions:
		get_marble_instance(position).selected = false
	selected_line = null


func set_player_turn_label(player):
	var color = Global.MARBLE_COLORS[player]
	var prefix = "Player"
	if player_modes[current_player_index] == Global.PlayerMode.AI:
		prefix = "Comp"
	player_turn_label.text = prefix + " " + String(player) + "'s Turn"
	player_turn_label.add_color_override("font_color", color)


func update_score():
	player_1_score.text = "%02d" % (player_2_marbles - state.player_marbles(2).size())
	player_1_score.add_color_override("font_color", Global.MARBLE_COLORS[1])
	player_2_score.text = "%02d" % (player_1_marbles - state.player_marbles(1).size())
	player_2_score.add_color_override("font_color", Global.MARBLE_COLORS[2])