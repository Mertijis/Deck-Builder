extends Node

const CARD_SMALLER_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2
const START_HEALTH = 10
const BATTLE_POS_OFFSET = 25

var battle_timer
var empty_card_slots = []
var ocupado_card_slot = []
var enemy_card_slots = []
var enemy_cards_on_battlefield = []
var player_cards_on_battlefield = []
var player_cards_that_attacked_this_turn = []
var enemy_cards_that_attacked_this_tur = []
var player_health
var enemy_health
var is_enemy_turn = false
var random_empty_card_slots
var tela_derrota
var played_card_this_turn = false  # Adicionado para controlar jogadas por turno

# Called when the node enters the scene tree for the first time.
func _ready():
	tela_derrota = $"../Tela Derrota".get_node("texto")
	battle_timer = $"../battleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	enemy_card_slots.append($"../CardSlots/EnemyCardSlot1")
	enemy_card_slots.append($"../CardSlots/EnemyCardSlot2")
	enemy_card_slots.append($"../CardSlots/EnemyCardSlot3")
	enemy_card_slots.append($"../CardSlots/EnemyCardSlot4")
	
	player_health = START_HEALTH
	$"../PlayerHealth".text = str(player_health)
	enemy_health = START_HEALTH
	$"../EnemyHealth".text = str(enemy_health)

func _on_end_turn_button_pressed():
	#$"../Deck".draw_card()
	is_enemy_turn = true
	$"../CardManager".unselect_select_card()
	player_cards_that_attacked_this_turn = []
	played_card_this_turn = false  # Resetar ao iniciar turno inimigo
	opponent_turn()
	
func reset_played_card():
	played_card_this_turn = false

func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false

	await wait(1.0)

	# Atualiza listas de slots vazios/ocupados
	empty_card_slots = []
	ocupado_card_slot = []

	for slot in enemy_card_slots:
		if slot.card_in_slot == false:
			empty_card_slots.append(slot)
		else:
			ocupado_card_slot.append(slot)

	# Puxa 1 carta do baralho (se houver)
	if $"../EnemyDeck".enemy_deck.size() != 0:
		$"../EnemyDeck".draw_card()
		await wait(1.0)

	# Joga APENAS 1 CARTA (se houver slots vazios)
	if empty_card_slots.size() > 0 and $"../Enemyhand".enemy_hand.size() > 0:
		await try_play_card_with_highest_attack()
		await wait(1.0)

	# Ataques com cartas no campo
	if enemy_cards_on_battlefield.size() != 0:
		var enemy_cards_to_attack = enemy_cards_on_battlefield.duplicate()
		for card in enemy_cards_to_attack:
			if card not in enemy_cards_that_attacked_this_tur:
				if is_instance_valid(card) and card.poder > 0:
					if player_cards_on_battlefield.size() != 0:
						var card_to_attack = player_cards_on_battlefield.pick_random()
						if is_instance_valid(card_to_attack):
							await attack(card, card_to_attack, "enemy")
							enemy_cards_that_attacked_this_tur.append(card)
					else:
						await direct_attack(card, "enemy")
	
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
		if player_health == 0:
			lose("player")
	else:
		enemy_health = max(0, enemy_health - attacking_card.poder)
		$"../EnemyHealth".text = str(enemy_health)
		if enemy_health == 0:
			lose("enemy")
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_in.position, CARD_MOVE_SPEED)
	attacking_card.z_index = 0
	await wait(1.0)
	

func attack(attacking_card, defendign_card, attacker):
	
	apply_type_advantage(attacking_card, defendign_card)
	attacking_card.vida = attacking_card.poder
	defendign_card.vida = defendign_card.poder
	
	if attacker == "player":
		$"../CardManager".selected_card_for_attack = null  # Desseleciona após ataque
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
	
	defendign_card.get_node("Poder").text = str(defendign_card.vida)
	attacking_card.get_node("Poder").text = str(attacking_card.vida)
	
	defendign_card.poder = defendign_card.vida
	attacking_card.poder = attacking_card.vida
	
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

func apply_type_advantage(attacking_card, defending_card):
	# 1 - One Pice
	# 2 - Naruto
	# 3 - Dragon Ball
	
	# Guarda valores originais
	var original_attacker_power = attacking_card.poder
	var original_defender_power = defending_card.poder
	
	# Aplica vantagem de ataque
	if attacking_card.anime == 1 and defending_card.anime == 2:
		attacking_card.poder = int(ceil(attacking_card.poder * 1.5))
	
	elif attacking_card.anime  == 2 and defending_card.anime == 3:
		attacking_card.poder = int(ceil(attacking_card.poder * 1.5))
	
	elif attacking_card.anime  == 3 and defending_card.anime == 1:
		attacking_card.poder = int(ceil(attacking_card.poder * 1.5))
	
	# Aplica vantagem na DEFESA (contra-ataque)
	if defending_card.anime == 1 and attacking_card.anime  == 2:
		defending_card.poder = int(ceil(defending_card.poder * 1.5))
	
	elif defending_card.anime == 2 and attacking_card.anime  == 3:
		defending_card.poder = ceil(ceil(defending_card.poder * 1.5))
	
	elif defending_card.anime == 3 and attacking_card.anime  == 1:
		defending_card.poder = int(ceil(defending_card.poder * 1.5))
	
	# Restaura valores após a batalha
	#attacking_card.vida = attacking_card.poder
	#defending_card.vida = defending_card.poder
	#attacking_card.poder = original_attacker_power
	#defending_card.poder = original_defender_power


func destroy_card(card, card_owner):
	if !is_instance_valid(card):
		return
	
	var slot_to_free = card.card_slot_card_in
	
	if card_owner == "player":
		card.get_node("Area2D/CollisionShape2D").disabled = true
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
		if slot_to_free:
			slot_to_free.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		if card in enemy_cards_on_battlefield:
			enemy_cards_on_battlefield.erase(card)
		if slot_to_free and slot_to_free in ocupado_card_slot:
			ocupado_card_slot.erase(slot_to_free)
	
	if slot_to_free:
		slot_to_free.card_in_slot = false
		if slot_to_free not in empty_card_slots:
			empty_card_slots.append(slot_to_free)
	
	var new_pos
	if card_owner == "player":
		new_pos = $"../PlayerDiscard".position
	else:
		new_pos = $"../EnemyDiscard".position
	
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)

func try_play_card_with_highest_attack():
	var enemy_hands = $"../Enemyhand".enemy_hand
	if enemy_hands.size() == 0:
		return

	# Escolhe um slot vazio aleatório
	random_empty_card_slots = empty_card_slots.pick_random()
	if !random_empty_card_slots:
		return

	# Marca slot como ocupado e atualiza listas
	random_empty_card_slots.card_in_slot = true
	empty_card_slots.erase(random_empty_card_slots)
	ocupado_card_slot.append(random_empty_card_slots)

	# Encontra carta com maior ataque na mão
	var card_with_highest_atk = enemy_hands[0]
	for card in enemy_hands:
		if card.poder > card_with_highest_atk.poder:
			card_with_highest_atk = card

	# Move a carta para o slot
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_atk, "position", random_empty_card_slots.position, CARD_MOVE_SPEED)
	tween.parallel().tween_property(card_with_highest_atk, "scale", Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE), CARD_MOVE_SPEED)
	card_with_highest_atk.get_node("AnimationPlayer").play("RESET")

	# Atualiza referências
	$"../Enemyhand".remove_card_from_hand(card_with_highest_atk)
	card_with_highest_atk.card_slot_card_in = random_empty_card_slots
	enemy_cards_on_battlefield.append(card_with_highest_atk)
	enemy_cards_that_attacked_this_tur.append(card_with_highest_atk)

	await wait(1.0)

func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout
	
func enemy_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_card_for_attack
	if attacking_card and defending_card in enemy_cards_on_battlefield:
		attack(attacking_card, defending_card, "player")

func end_oponent_turn():
	is_enemy_turn =  false
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
	$"../CardManager".reset_played_card()
	$"../Deck".reset_draw()
	$"../Deck".draw_card()
	enemy_cards_that_attacked_this_tur = []

func lose(loser):
	await wait(1.0)
	if loser == "player":
		$"../Tela Derrota".visible = true
		tela_derrota.text = "Você Perdeu"
		await  wait(5.0)
		get_tree().reload_current_scene()
	else:
		$"../Tela Derrota".visible = true
		tela_derrota.text = "Você Ganhou"
		$"../EndTurnButton".disabled = true
		await  wait(5.0)
		get_tree().reload_current_scene()

# Nova função para posicionar carta no campo
func place_card_on_slot(card, card_slot):
	if played_card_this_turn:
		return false
	
	played_card_this_turn = true
	card.z_index = 0
	card.card_slot_card_in = card_slot
	card_slot.card_in_slot = true
	card_slot.get_node("Area2D/CollisionShape2D").disabled = true
	
	player_cards_on_battlefield.append(card)
	player_cards_that_attacked_this_turn.append(card)
	
	return true
