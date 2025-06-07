extends Node2D

const CARD_SCENE_PATH = "res://Scenes/Enemycard.tscn"
const CARD_DRAW_SPEED = 0.2
const START_CARDS = 4

var enemy_deck = []
var card_database_reference

func cards_to_deck():
	for card in card_database_reference.CARDS:
		enemy_deck.append(card)

# Called when the node enters the scene tree for the first time.
func _ready():
	card_database_reference = preload("res://Scripts/CardsDataBase.gd")
	cards_to_deck()
	enemy_deck.shuffle()
	$Deck/EnemyText.text = str(enemy_deck.size())
	#Criar loop que distribui 4 cartas de figurante, aleatoriamente
	for i in range(START_CARDS):
		draw_card()


func draw_card():
	var card_draw_name = enemy_deck[0]
	var card_anime = card_database_reference.CARDS[card_draw_name][2]
	enemy_deck.erase(card_draw_name)
	
	if enemy_deck.size() == 0:
		$Deck/Sprite2D.visible = false
		$Deck/EnemyText.visible= false
	
	
	
	$Deck/EnemyText.text = str(enemy_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://Assets/CardsImage/" + card_draw_name + ".jpg" )
	var card_anime_path = "res://Assets/CardsImage/" + card_anime + ".png"
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.get_node("AnimeLogo").texture = load(card_anime_path)
	new_card.poder = card_database_reference.CARDS[card_draw_name][0]
	new_card.poder_original = card_database_reference.CARDS[card_draw_name][0]
	new_card.vida = card_database_reference.CARDS[card_draw_name][0]
	new_card.anime = card_database_reference.CARDS[card_draw_name][1]
	new_card.get_node("Poder").text = str(new_card.poder)
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../Enemyhand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	
