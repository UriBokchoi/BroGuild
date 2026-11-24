class_name PactPanel
extends ModalPanel
## Los pactos que ofrece el heraldo del Gremio: pausa y enseña una carta por pacto y un botón para
## rechazarlos. El pacto elegido (su premio y su maldición) se suma a las stats del jugador para el
## resto de la partida, y el HUD lo avisa.

## Las stats del jugador.
@export var stats: StatsComponent
## Aviso en el HUD al sellar un pacto (con su nombre).
@export var sealed_key: StringName = &"PACT_SEALED"
@export var sealed_color: Color = Color.WHITE

## Pactos sellados en esta partida, por orden.
var _sealed: Array[PactData] = []
## Origen de los modificadores de cada uno (el StatBlock guarda cada modificador con el suyo).
var _sources: Array[RefCounted] = []

@onready var _cards: HBoxContainer = %Cards
@onready var _reject: Button = %Reject


func _enter_tree() -> void:
	if not EventBus.pact_offered.is_connected(open):
		EventBus.pact_offered.connect(open)


func _ready() -> void:
	super()
	_reject.pressed.connect(reject)


## Enseña [param pacts] para elegir uno o rechazarlos. Sin pactos, nada.
func open(pacts: Array[PactData]) -> void:
	if pacts.is_empty():
		return
	for card: Node in _cards.get_children():
		card.free()
	for pact: PactData in pacts:
		var card := PactCard.new(pact, stats)
		card.pressed.connect(choose.bind(pact))
		_cards.add_child(card)
	_set_open(true)


## Sella [param pact]: su premio y su maldición van a las stats del jugador. Y cierra.
func choose(pact: PactData) -> void:
	if is_instance_valid(stats):
		# Cada pacto con su propio origen: se podría quitar uno sin tocar los demás.
		var source := RefCounted.new()
		_sources.append(source)
		for modifier: StatModifier in pact.modifiers():
			stats.add_modifier(modifier, source)
	_sealed.append(pact)
	EventBus.announced.emit(sealed_key, [pact.name_key], sealed_color)
	_set_open(false)


## No sella ninguno. Y cierra.
func reject() -> void:
	_set_open(false)


## Pactos sellados en esta partida, por orden.
func get_sealed() -> Array[PactData]:
	return _sealed.duplicate()


## Cartas que enseña ahora (para tests).
func get_cards() -> Array[PactCard]:
	var cards: Array[PactCard] = []
	for child: Node in _cards.get_children():
		cards.append(child as PactCard)
	return cards
