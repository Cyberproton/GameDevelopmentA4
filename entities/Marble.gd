extends Node2D


onready var sprite = $Sprite

var grid_position: Array
var marble: int setget set_marble
var selected: bool = false setget set_selected

signal player_select_marble(marble, position)


func _ready():
	update_color()


func set_marble(value: int):
	marble = value
	if is_inside_tree():
		update_color()


func set_selected(value: bool):
	if selected == value:
		return
	selected = value
	update_color()


func _on_Detector_mouse_entered():
	if selected:
		return
	update_color()


func _on_Detector_mouse_exited():
	if selected: 
		return
	update_color()


func _on_Detector_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton:
		if event.pressed:
			emit_signal("player_select_marble", marble, grid_position + [])


func update_color():
	if marble == null:
		if selected:
			sprite.modulate = Global.SELECTED_MARBLE_COLORS[0]
		else:
			sprite.modulate = Global.MARBLE_COLORS[0]
	else:
		if selected:
			sprite.modulate = Global.SELECTED_MARBLE_COLORS[marble]
		else:
			sprite.modulate = Global.MARBLE_COLORS[marble]
