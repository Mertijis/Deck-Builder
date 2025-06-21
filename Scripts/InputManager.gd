extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const COLLISION_MASK_ENEMY_CARD = 8

var card_manager_reference
var battle_manager_reference

func _ready() -> void:
	card_manager_reference = $"../CardManager"
	battle_manager_reference = $"../battleManager"

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("left_mouse_button_clicked")
			raycast_at_cursor()
		else:
			emit_signal("left_mouse_button_released")

func raycast_at_cursor():
	var space_state = get_viewport().world_2d.direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_viewport().get_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD | COLLISION_MASK_CARD_SLOT | COLLISION_MASK_ENEMY_CARD
	
	var results = space_state.intersect_point(parameters)
	if results.size() == 0:
		# Desseleciona cartas se clicou em área vazia
		card_manager_reference.unselect_select_card()
		return
	
	# Encontra o objeto com maior z-index
	var highest_z_index = -1
	var selected_result = null
	
	for result in results:
		var parent = result.collider.get_parent()
		if parent.z_index > highest_z_index:
			highest_z_index = parent.z_index
			selected_result = result
	
	if not selected_result:
		return
		
	var result_collision_mask = selected_result.collider.collision_mask
	
	# Verifica cartas do jogador
	if result_collision_mask == COLLISION_MASK_CARD:
		var card_found = selected_result.collider.get_parent()
		if card_found:
			card_manager_reference.card_clicked(card_found)
	
	# Verifica cartas inimigas
	elif result_collision_mask == COLLISION_MASK_ENEMY_CARD:
		var enemy_card = selected_result.collider.get_parent()
		# Só permite seleção se for turno do jogador e carta estiver no campo
		if not battle_manager_reference.is_enemy_turn and enemy_card in battle_manager_reference.enemy_cards_on_battlefield:
			battle_manager_reference.enemy_card_selected(enemy_card)
	
	# Verifica slots de carta
	elif result_collision_mask == COLLISION_MASK_CARD_SLOT:
		var card_slot = selected_result.collider.get_parent()
		# Se tivermos uma carta selecionada para posicionamento, coloque no slot
		if card_manager_reference.selected_card_for_placement:
			card_manager_reference.place_selected_card_on_slot(card_slot)
