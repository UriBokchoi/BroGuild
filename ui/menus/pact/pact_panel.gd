class_name PactPanel
extends ModalPanel
## Los pactos que ofrece el heraldo del Gremio: pausa y enseña una carta por pacto, un botón para
## pedir otros por oro (cada vez más caro en la partida) y otro para rechazarlos. El pacto elegido (su
## premio y su maldición) se suma a las stats del jugador para el resto de la partida, y el HUD lo
## avisa.

## Las stats del jugador.
@export var stats: StatsComponent
## El oro del jugador (para volver a tirar).
@export var wallet: WalletComponent
## De dónde salen los pactos al volver a tirar, y cuánto cuesta.
@export var data: HeraldData
## Aviso en el HUD al sellar un pacto (con su nombre).
@export var sealed_key: StringName = &"PACT_SEALED"
@export var sealed_color: Color = Color.WHITE

## Pactos sellados en esta partida, por orden.
var _sealed: Array[PactData] = []
## Origen de los modificadores de cada uno (el StatBlock guarda cada modificador con el suyo).
var _sources: Array[RefCounted] = []
## Azar de los pactos nuevos. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## Rng.
var rng: RandomNumberGenerator

## Veces que se volvió a tirar en la partida (sube el coste).
var _rerolls: int = 0
## Pactos que se enseñan ahora.
var _shown: Array[PactData] = []

@onready var _cards: HBoxContainer = %Cards
@onready var _reroll: Button = %Reroll
@onready var _reject: Button = %Reject


func _enter_tree() -> void:
	if not EventBus.pact_offered.is_connected(open):
		EventBus.pact_offered.connect(open)


func _ready() -> void:
	super()
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	_reroll.pressed.connect(reroll)
	_reject.pressed.connect(reject)


## Enseña [param pacts] para elegir uno o rechazarlos. Sin pactos, nada.
func open(pacts: Array[PactData]) -> void:
	if pacts.is_empty():
		return
	_show(pacts)
	_set_open(true)


## Cambia los pactos por otros (distintos de los de ahora si quedan) a cambio de oro. Devuelve si
## pudo (sin oro suficiente, no).
func reroll() -> bool:
	if not is_open() or data == null or wallet == null or not wallet.spend(reroll_cost()):
		return false
	_rerolls += 1
	_show(data.roll(rng, _shown))
	return true


## Oro que cuesta volver a tirar ahora.
func reroll_cost() -> int:
	return data.reroll_cost_at(_rerolls) if data else 0


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


## ¿Se puede volver a tirar ahora (hay con qué y oro suficiente)?
func can_reroll() -> bool:
	return not _reroll.disabled


func _show(pacts: Array[PactData]) -> void:
	_shown = pacts.duplicate()
	for card: Node in _cards.get_children():
		card.free()
	for pact: PactData in pacts:
		var card := PactCard.new(pact, stats)
		card.pressed.connect(choose.bind(pact))
		_cards.add_child(card)
	var cost := reroll_cost()
	_reroll.text = tr(&"PACT_REROLL") % cost
	_reroll.disabled = data == null or wallet == null or wallet.get_gold() < cost


## Cartas que enseña ahora (para tests).
func get_cards() -> Array[PactCard]:
	var cards: Array[PactCard] = []
	for child: Node in _cards.get_children():
		cards.append(child as PactCard)
	return cards
