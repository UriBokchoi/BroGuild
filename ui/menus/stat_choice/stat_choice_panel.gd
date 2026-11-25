class_name StatChoicePanel
extends ModalPanel
## Elegir una mejora de stats (la que ofrece una pesa-santuario): pausa, enseña una carta por oferta
## y la elegida se suma a las stats del jugador para el resto de la partida.

## Las stats del jugador.
@export var stats: StatsComponent

## Origen de las mejoras ya elegidas (el StatBlock guarda cada modificador con el suyo).
var _sources: Array[RefCounted] = []

@onready var _cards: HBoxContainer = %Cards


func _enter_tree() -> void:
	if not EventBus.stat_choice_offered.is_connected(open):
		EventBus.stat_choice_offered.connect(open)


## Enseña [param offers] para elegir una. Sin ofertas, nada.
func open(offers: Array[StatOffer]) -> void:
	if offers.is_empty():
		return
	for card: Node in _cards.get_children():
		card.free()
	for offer: StatOffer in offers:
		var card := StatChoiceCard.new(offer, stats)
		card.pressed.connect(choose.bind(offer))
		_cards.add_child(card)
	_set_open(true)


## Se queda con [param offer]: su mejora va a las stats del jugador. Y cierra.
func choose(offer: StatOffer) -> void:
	if is_instance_valid(stats):
		var source := RefCounted.new()
		_sources.append(source)
		stats.add_modifier(offer.modifier(), source)
	_set_open(false)


## Cartas que enseña ahora (para tests).
func get_cards() -> Array[StatChoiceCard]:
	var cards: Array[StatChoiceCard] = []
	for child: Node in _cards.get_children():
		cards.append(child as StatChoiceCard)
	return cards
