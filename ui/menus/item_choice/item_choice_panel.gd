class_name ItemChoicePanel
extends ModalPanel
## Elegir un objeto pasivo (el círculo de setas, EventBus.item_choice_offered): pausa el juego, pide
## el cursor y muestra una carta por objeto y un botón para pedir otros por oro, cada vez más caro en
## la partida. Hay que elegir: Esc no la salta. El elegido va a los objetos del jugador.

## Adonde va el objeto elegido (los objetos del jugador; su Suerte ayuda al volver a tirar).
@export var inventory: PassiveInventory
## El oro del jugador (para volver a tirar).
@export var wallet: WalletComponent
## De dónde salen los objetos al volver a tirar (el del círculo de setas).
@export var pool: ItemPool
## Oro que cuesta el primer «volver a tirar» de la partida y cuánto se multiplica con cada uso.
@export_range(0, 1000, 1, "or_greater") var reroll_cost: int = 0
@export_range(1.0, 5.0, 0.05) var reroll_growth: float = 1.0

## Azar de los objetos nuevos. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## Rng.
var rng: RandomNumberGenerator

## Veces que se volvió a tirar en la partida (sube el coste).
var _rerolls: int = 0
## Objetos que se enseñan ahora y los que pueden salir.
var _shown: Array[PassiveItemData] = []
var _catalog: Array[PassiveItemData] = []

@onready var _cards: HBoxContainer = %Cards
@onready var _reroll: Button = %Reroll


func _enter_tree() -> void:
	if not EventBus.item_choice_offered.is_connected(open):
		EventBus.item_choice_offered.connect(open)


func _ready() -> void:
	super()
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	if pool:
		_catalog = pool.load_catalog()
	_reroll.pressed.connect(reroll)


## Muestra [param items] para elegir uno. Sin objetos, nada.
func open(items: Array[PassiveItemData]) -> void:
	if items.is_empty():
		return
	_show(items)
	_set_open(true)


## Cambia los objetos por otros (distintos de los de ahora si quedan bastantes) a cambio de oro.
## Devuelve si pudo (sin oro suficiente, no).
func reroll() -> bool:
	if not is_open() or pool == null or wallet == null or not wallet.spend(current_reroll_cost()):
		return false
	_rerolls += 1
	var fresh := _catalog.filter(func(item: PassiveItemData) -> bool: return not _shown.has(item))
	var catalog: Array[PassiveItemData] = []
	catalog.assign(fresh if fresh.size() >= _shown.size() else _catalog)
	var luck := inventory.stats.get_value(&"luck") if is_instance_valid(inventory) else 0.0
	_show(pool.roll_several(catalog, _shown.size(), luck, rng))
	return true


## Oro que cuesta volver a tirar ahora.
func current_reroll_cost() -> int:
	return roundi(reroll_cost * pow(reroll_growth, _rerolls))


## ¿Se puede volver a tirar ahora (hay con qué y oro suficiente)?
func can_reroll() -> bool:
	return not _reroll.disabled


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


func _show(items: Array[PassiveItemData]) -> void:
	_shown = items.duplicate()
	for card: Node in _cards.get_children():
		card.free()
	for item: PassiveItemData in items:
		var card := ItemChoiceCard.new(item, inventory.stats if is_instance_valid(inventory) else null)
		card.pressed.connect(choose.bind(item))
		_cards.add_child(card)
	var cost := current_reroll_cost()
	_reroll.text = tr(&"ITEM_CHOICE_REROLL") % cost
	_reroll.disabled = pool == null or wallet == null or wallet.get_gold() < cost
