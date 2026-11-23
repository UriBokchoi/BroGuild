class_name ItemChoicePanel
extends ModalPanel
## Elegir un objeto pasivo (el círculo de setas, [signal EventBus.item_choice_offered]): pausa el
## juego, pide el cursor y muestra una carta por objeto. Hay que elegir: Esc no la salta
## ([ModalPanel]). El elegido va al inventario del jugador ([member inventory]) y el juego sigue.

## Adonde va el objeto elegido (los objetos del jugador).
@export var inventory: PassiveInventory

@onready var _cards: HBoxContainer = %Cards


func _enter_tree() -> void:
	if not EventBus.item_choice_offered.is_connected(open):
		EventBus.item_choice_offered.connect(open)


## Muestra [param items] para elegir uno. Sin objetos, nada.
func open(items: Array[PassiveItemData]) -> void:
	if items.is_empty():
		return
	for card: Node in _cards.get_children():
		card.free()
	for item: PassiveItemData in items:
		var card := ItemChoiceCard.new(item, inventory.stats if is_instance_valid(inventory) else null)
		card.pressed.connect(choose.bind(item))
		_cards.add_child(card)
	_set_open(true)


## Se queda con [param item] y cierra.
func choose(item: PassiveItemData) -> void:
	if is_instance_valid(inventory):
		inventory.add(item)
	_set_open(false)


## Cartas que muestra ahora (para tests).
func get_cards() -> Array[ItemChoiceCard]:
	var cards: Array[ItemChoiceCard] = []
	for child: Node in _cards.get_children():
		cards.append(child as ItemChoiceCard)
	return cards
