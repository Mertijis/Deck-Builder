extends Node2D

const COLLISION_MASK = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SIZE = 0.65
const HOVERD_CARD_SIZE = 0.75

var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference
var played_card_this_turn = false
var selected_card

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if card_being_dragged:
		var mouse_position = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_position.x, 0, screen_size.x), 
			clamp(mouse_position.y, 0, screen_size.y))
			

func card_clicked(card):
	if card.card_slot_card_in:
		if $"../battleManager".is_enemy_turn == false:
			if card not in $"../battleManager".player_cards_that_attacked_this_turn:
				if $"../battleManager".enemy_cards_on_battlefield.size() == 0:
					$"../battleManager".direct_attack(card,"player")
					return
				else: 
					select_card_for_battle(card)
	else:
		start_drag(card)


func select_card_for_battle(card):
	if selected_card:
		if selected_card == card:
			card.position.y += 20
			selected_card = null
		else:
			selected_card.position.y += 20
			selected_card = card
			card.position.y -= 20
	else:
		selected_card = card
		card.position.y -= 20
	
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
			$"../battleManager".player_cards_on_battlefield.append(card_being_dragged)
			$"../battleManager".player_cards_that_attacked_this_turn.append(card_being_dragged)
			card_being_dragged = null
			return
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null

func unselect_select_card():
	if selected_card:
		selected_card.position.y += 20
		selected_card = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
func on_left_click_released():
	if card_being_dragged:
		finish_drag()

func on_hovered_over_card(card):
	if card.card_slot_card_in:
		return
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highligth_card(card, true)

func on_hovered_off_card(card):
	if !card.card_slot_card_in && !card_being_dragged:
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
		#return get_card_with_highest_z_index(result)
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
