extends Node


const DIRECTIONS := [[0, 1], [1, 0], [1, 1], [0, -1], [-1, 0], [-1, -1]]
const ORIENTATIONS := [[0, 1], [1, 0], [1, 1]]
const NEGATIVE_ORIENTATIONS := [[0, -1], [-1, 0], [-1, -1]]
const MAX_MARBLES_PER_LINE := 3
const MAX_PUSH_STRENGTH := 2
const GAME_OVER_MARBLES := 6

const BOARD_SIZE = [9, 9]
const MARBLE_SIZE = 64
const MARBLE_COLORS = [
	Color8(200, 200, 220),
	Color8(89, 207, 147),
	Color8(226, 114, 133),
]
const SELECTED_MARBLE_COLORS = [
	Color8(200, 200, 220),
	Color8(151, 237, 202),
	Color8(246, 162, 168),
]

const GROUP_MARBLES = "marbles"

const CONTROL_DIRECTIONS = {
	KEY_W: [-1, -1],
	KEY_E: [-1, 0],
	KEY_A: [0, -1],
	KEY_D: [0, 1],
	KEY_Z: [1, 0],
	KEY_X: [1, 1],
}
enum PlayerMode {
	PLAYER = 0,
	AI = 1,
}
enum AIPolicy {
	RANDOM = 0,
	MINIMAX = 1,
}

const SERVER_IP := ""
const SERVER_PORT := 9999
const MAX_CLIENT := 2


func pause_game(pause = null):
	if pause == null:
		get_tree().paused = !get_tree().paused
	else: 
		get_tree().paused = pause
