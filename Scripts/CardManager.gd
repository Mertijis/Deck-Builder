extends Node2D

const COLLISION_MASK = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SIZE = 0.65
const HOVERD_CARD_SIZE = 0.75
const SHAKE_ANGLE = 0.15

var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference
var battle_manager_reference
var played_card_this_turn = false
var selected_card_for_attack  # Renomeado para maior clareza
var selected_card_for_placement  # Nova variável para carta selecionada para posicionamento

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	battle_manager_reference = $"../battleManager"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)

func card_clicked(card):
	if card.card_slot_card_in:
		# Carta já está no campo de batalha
		if battle_manager_reference.is_enemy_turn == false:
			if card not in battle_manager_reference.player_cards_that_attacked_this_turn:
				if battle_manager_reference.enemy_cards_on_battlefield.size() == 0:
					battle_manager_reference.direct_attack(card,"player")
					return
				else: 
					select_card_for_battle(card)
	else:
		# Carta está na mão - seleciona para posicionamento
		select_card_for_placement(card)


func select_card_for_placement(card):
	# Desseleciona qualquer carta anterior
	if selected_card_for_placement:
		selected_card_for_placement.position.y += 20
		selected_card_for_placement.scale = Vector2(DEFAULT_CARD_SIZE, DEFAULT_CARD_SIZE)
		selected_card_for_placement.z_index = 1
		selected_card_for_placement = null
	
	# Seleciona a nova carta
	selected_card_for_placement = card
	card.scale = Vector2(HOVERD_CARD_SIZE, HOVERD_CARD_SIZE)
	card.z_index = 3  # Coloca acima de outras cartas
	card.position.y -= 20  # Move ligeiramente para cima como feedback visual


func select_card_for_battle(card):
	# Desseleciona carta de posicionamento se houver
	if selected_card_for_placement:
		selected_card_for_placement.position.y += 20
		selected_card_for_placement.scale = Vector2(DEFAULT_CARD_SIZE, DEFAULT_CARD_SIZE)
		selected_card_for_placement.z_index = 1
		selected_card_for_placement = null
	
	# Seleciona carta para batalha
	if selected_card_for_attack:
		if selected_card_for_attack == card:
			card.position.y += 20
			selected_card_for_attack = null
		else:
			selected_card_for_attack.position.y += 20
			selected_card_for_attack = card
			card.position.y -= 20
	else:
		selected_card_for_attack = card
		card.position.y -= 20


func place_selected_card_on_slot(card_slot):
	if selected_card_for_placement and !played_card_this_turn:
		var card = selected_card_for_placement
		played_card_this_turn = true
		
		# Posiciona a carta no slot
		card.z_index = 0  # Volta ao z-index normal
		card.card_slot_card_in = card_slot
		player_hand_reference.remove_card_from_hand(card)
		card.position = card_slot.position
		battle_manager_reference.play_placement_sound()
		card.scale = Vector2(DEFAULT_CARD_SIZE, DEFAULT_CARD_SIZE)
		
		# Atualiza o slot
		card_slot.card_in_slot = true
		card_slot.get_node("Area2D/CollisionShape2D").disabled = true
		
		# Atualiza o gerenciador de batalha
		battle_manager_reference.player_cards_on_battlefield.append(card)
		battle_manager_reference.player_cards_that_attacked_this_turn.append(card)
		card.set_exhausted(true)
		
		# Limpa seleção
		selected_card_for_placement = null
		return true
		
	return false


func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SIZE, DEFAULT_CARD_SIZE)
	
func finish_drag():
	if card_being_dragged:
		card_being_dragged.scale = Vector2(DEFAULT_CARD_SIZE, DEFAULT_CARD_SIZE)
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		if !played_card_this_turn:
			played_card_this_turn = true
			card_being_dragged.z_index += -1
			is_hovering_on_card = false
			card_being_dragged.card_slot_card_in = card_slot_found
			player_hand_reference.remove_card_from_hand(card_being_dragged)
			card_being_dragged.position = card_slot_found.position
			card_slot_found.card_in_slot = true
			card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true
			battle_manager_reference.player_cards_on_battlefield.append(card_being_dragged)
			battle_manager_reference.player_cards_that_attacked_this_turn.append(card_being_dragged)
			card_being_dragged = null
			return
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null

func unselect_select_card():
	# Desseleciona ambos os tipos de seleção
	if selected_card_for_attack:
		selected_card_for_attack.position.y += 20
		selected_card_for_attack = null
		
	if selected_card_for_placement:
		selected_card_for_placement.position.y += 20
		selected_card_for_placement.scale = Vector2(DEFAULT_CARD_SIZE, DEFAULT_CARD_SIZE)
		selected_card_for_placement.z_index = 1
		selected_card_for_placement = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
func on_left_click_released():
	if card_being_dragged:
		finish_drag()
	else:
		# Verifica se clicou em um slot com uma carta selecionada para posicionamento
		var card_slot_found = raycast_check_for_card_slot()
		if card_slot_found and selected_card_for_placement:
			place_selected_card_on_slot(card_slot_found)

func on_hovered_over_card(card):
	if card.card_slot_card_in or card == selected_card_for_placement:
		return
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highligth_card(card, true)

func on_hovered_off_card(card):
	if !card.card_slot_card_in && !card_being_dragged && card != selected_card_for_placement:
		highligth_card(card, false)
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highligth_card(new_card_hovered, true)
		else:
			is_hovering_on_card = null

func highligth_card(card, hovered):
	if hovered:
		card.scale = Vector2(HOVERD_CARD_SIZE, HOVERD_CARD_SIZE)
		card.z_index = 2
	else: 
		card.scale = Vector2(DEFAULT_CARD_SIZE, DEFAULT_CARD_SIZE)
		card.z_index = 1
		
func raycast_check_for_card_slot():
	var space_state = get_viewport().world_2d.direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_viewport().get_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func raycast_check_for_card():
	var space_state = get_viewport().world_2d.direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_viewport().get_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
	
	
func reset_played_card():
	played_card_this_turn = false
	
