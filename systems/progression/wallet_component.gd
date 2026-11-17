class_name WalletComponent
extends Node
## Oro de quien lo gana (el jugador) en la partida: la moneda que se gasta en ella (GDD §9; antes,
## «fichas»). Suma lo que recoge de su tipo de recompensa ([member reward], por
## [code]EventBus.pickup_collected[/code]) multiplicado por su stat [code]currency_gain[/code].

## Cambió el oro.
signal gold_changed(gold: float)

## Stats de quien gana el oro (su [code]currency_gain[/code]).
@export var stats: StatsComponent
## Recompensa de los recogibles que cuentan como oro.
@export var reward: StringName = &"gold"

var _gold: float = 0.0


func _enter_tree() -> void:
	if not EventBus.pickup_collected.is_connected(_on_pickup_collected):
		EventBus.pickup_collected.connect(_on_pickup_collected)


## Suma [param amount] de oro (antes de [code]currency_gain[/code]).
func add(amount: float) -> void:
	if amount <= 0.0:
		return
	_gold += amount * _gain()
	gold_changed.emit(_gold)


## Gasta [param amount] si le llega; devuelve si pudo.
func spend(amount: float) -> bool:
	if amount > _gold:
		return false
	_gold -= amount
	gold_changed.emit(_gold)
	return true


func get_gold() -> float:
	return _gold


func _gain() -> float:
	return stats.get_value(&"currency_gain") / 100.0 if stats else 1.0


func _on_pickup_collected(kind: StringName, amount: float) -> void:
	if kind == reward:
		add(amount)
