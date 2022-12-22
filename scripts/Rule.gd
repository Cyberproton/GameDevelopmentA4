class_name Rule


var max_marbles_per_line: int
var max_push_strength: int
var game_over_marbles: int
var initial_state: Array


func _init(
	initial_state, 
	game_over_marbles = Global.GAME_OVER_MARBLES, 
	max_marbles_per_line = Global.MAX_MARBLES_PER_LINE, 
	max_push_strength = Global.MAX_PUSH_STRENGTH
):
	self.initial_state = initial_state
	self.game_over_marbles = game_over_marbles
	self.max_marbles_per_line = max_marbles_per_line
	self.max_push_strength = max_push_strength