extends Node

const CARD_SMALLER_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2
const START_HEALTH = 10
const BATTLE_POS_OFFSET = 25

var battle_timer
var empty_card_slots = []
var enemy_cards_on_battlefield = []
var player_cards_on_battlefield = []
var player_cards_that_attacked_this_turn = []
var player_health
var enemy_health
var is_enemy_turn = false

# Called when the node enters the scene tree for the first time.
func _ready():
	battle_timer = $"../battleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	empty_card_slots.append($"../CardSlots/EnemyCardSlot1")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot2")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot3")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot4")
	
	player_health = START_HEALTH
	$"../PlayerHealth".text = str(player_health)
	enemy_health = START_HEALTH
	$"../EnemyHealth".text = str(enemy_health)

func _on_end_turn_button_pressed():
	is_enemy_turn = true
	$"../CardManager".unselect_select_card()
	player_cards_that_attacked_this_turn = []
	opponent_turn()
	
	
func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	
	await  wait(1.0)
	
	if $"../EnemyDeck".enemy_deck.size() != 0:
		$"../EnemyDeck".draw_card()
		await wait(1.0)
	
	#check if slots are empty
	if empty_card_slots.size() != 0:
		await try_play_card_with_highest_attack()
	
	
	if enemy_cards_on_battlefield.size() != 0:
		var enemy_cards_to_attack = enemy_cards_on_battlefield.duplicate()
		for card in enemy_cards_to_attack:
			if player_cards_on_battlefield.size() != 0:
				var card_to_attack = player_cards_on_battlefield.pick_random()
				await attack(card, card_to_attack, "enemy")
			else:
				await direct_attack(card, "enemy")
	
	
	
	#end Turn
	end_oponent_turn()
	
	
func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "enemy":
		new_pos_y = 1080
	else:
		new_pos_y = 0
		player_cards_that_attacked_this_turn.append(attacking_card)
	var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	
	attacking_card.z_index = 5
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if attacker == "enemy":
		player_health = max(0, player_health - attacking_card.poder)
		$"../PlayerHealth".text = str(player_health)
	else:
		enemy_health = max(0, enemy_health - attacking_card.poder)
		$"../EnemyHealth".text = str(enemy_health)
	
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_in.position, CARD_MOVE_SPEED)
	attacking_card.z_index = 0
	await wait(1.0)
	

func attack(attacking_card, defendign_card, attacker):
	if attacker == "player":
		$"../CardManager".selected_card = null
		player_cards_that_attacked_this_turn.append(attacking_card)
	
	attacking_card.z_index = 5
	var new_pos = Vector2(defendign_card.position.x, defendign_card.position.y + BATTLE_POS_OFFSET)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_in.position, CARD_MOVE_SPEED)
	
	#card damage
	defendign_card.vida = max(0, (defendign_card.vida - attacking_card.poder))
	attacking_card.vida = max(0, (attacking_card.vida - defendign_card.poder))
	
	#defendign_card.get_node("Poder").text = str(defendign_card.vida)
	#attacking_card.get_node("Poder").text = str(attacking_card.vida)
	
	defendign_card.poder = defendign_card.vida
	attacking_card.poder = attacking_card.vida
	
	if attacking_card.poder == null:
		attacking_card.poder = 0
	
	#attacking_card.get_node("Poder").text = str(attacking_card.poder)
	
	await wait(1.0)
	attacking_card.z_index = 0
	
	var card_was_destroyed = false
	if attacking_card.poder == 0:
		destroy_card(attacking_card, attacker)
		card_was_destroyed = true
	if defendign_card.poder == 0:
		if attacker == "player":
			destroy_card(defendign_card, "enemy")
		else:
			destroy_card(defendign_card, "player")
		card_was_destroyed = true
	
	if card_was_destroyed:
		await wait(1.0)

func destroy_card(card, card_owner):
	var new_pos
	if card_owner == "player":
		card.get_node("Area2D/CollisionShape2D").disabled = true
		new_pos = $"../PlayerDiscard".position
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
		card.card_slot_card_in.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		new_pos = $"../EnemyDiscard".position
		if card in enemy_cards_on_battlefield:
			enemy_cards_on_battlefield.erase(card)
	
	card.card_slot_card_in.card_in_slot = false
	card.card_slot_card_in = null
	
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)

func enemy_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_card
	if attacking_card and defending_card in enemy_cards_on_battlefield:
		attack(attacking_card, defending_card, "player")



func try_play_card_with_highest_attack():
	var enemy_hands = $"../Enemyhand".enemy_hand
	if enemy_hands.size() == 0:
		end_oponent_turn()
		return
		
	
	var random_empty_card_slots = empty_card_slots.pick_random()
	empty_card_slots.erase(random_empty_card_slots)
	
	
	var card_with_highest_atk = enemy_hands[0]
	for card in enemy_hands:
		if card.poder > card_with_highest_atk.poder:
			card_with_highest_atk = card
	
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_atk, "position", random_empty_card_slots.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(card_with_highest_atk, "scale", Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE), CARD_MOVE_SPEED)
	card_with_highest_atk.get_node("AnimationPlayer").play("RESET")
	
	$"../Enemyhand".remove_card_from_hand(card_with_highest_atk)
	card_with_highest_atk.card_slot_card_in = random_empty_card_slots
	enemy_cards_on_battlefield.append(card_with_highest_atk)
	
	await wait(1.0)


func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout


func end_oponent_turn():
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_card()
	is_enemy_turn =  false
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
