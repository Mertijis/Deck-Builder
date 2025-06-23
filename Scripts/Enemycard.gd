extends Node2D

var starting_position
var poder
var poder_original
var vida
var card_slot_card_in
var anime

var is_exhausted = false
var original_rotation = 0.0
const EXHAUSTED_ROTATION = 0.35

func set_exhausted(state):
	is_exhausted = state
	if state:
		# Aplicar rotação permanente
		var tween = get_tree().create_tween()
		tween.tween_property(self, "rotation", EXHAUSTED_ROTATION, 0.2)
	else:
		# Remover rotação
		var tween = get_tree().create_tween()
		tween.tween_property(self, "rotation", original_rotation, 0.2)
		
func reset_visuals():
	is_exhausted = false
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation", original_rotation, 0.1)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
