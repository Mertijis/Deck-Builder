extends Node2D

var card_width
var hand_y_position
var center_screen_x

const DEFAULT_CARD_MOVE_SPEED = 0.2

var player_hand = []

func _ready() -> void:
	var screen_size = get_viewport().size
	center_screen_x = screen_size.x / 2
	hand_y_position = screen_size.y * 0.82
	card_width = screen_size.x * 0.12


func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_positions(speed)
	else:
		animate_card_to_position(card, card.starting_position, DEFAULT_CARD_MOVE_SPEED)


func update_hand_positions(speed):
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), hand_y_position)
		var card = player_hand[i]
		card.starting_position = new_position
		animate_card_to_position(card, new_position, speed)


func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * card_width
	var x_offset = center_screen_x + index * card_width - total_width / 2
	return x_offset


func animate_card_to_position(card, new_position, speed):
	if not $"../battleManager".player_health == 0 or not $"../battleManager".enemy_health == 0:
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", new_position, speed)


func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)
