extends Node2D

signal hovered
signal hovered_off

var starting_position
var card_slot_card_in
var poder
var vida
var anime

# Called when the node enters the scene tree for the first time.
func _ready():
	get_parent().connect_card_signals(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_mouse_entered():
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited():
	emit_signal("hovered_off", self)
