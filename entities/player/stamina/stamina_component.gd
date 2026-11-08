class_name StaminaComponent
extends Node
## Stamina del jugador por cargas: la gastan las acciones (dash, doble salto…) y se recarga
## sola. Máximo y recarga son stats ([StaminaData]), así que las mejoras los cambian en vivo.
## Avisa a la interfaz con [signal EventBus.player_stamina_changed].

signal changed(charges: float, max_charges: int)

## Stats de donde salen el máximo y la recarga.
@export var stats: StatsComponent

var _pool := StaminaPool.new()
var _data: StaminaData


func _ready() -> void:
	_data = stats.get_resolved(StaminaData) as StaminaData
	_pool.max_charges = _data.max_charges
	_pool.fill()
	_notify()


func _physics_process(delta: float) -> void:
	var max_changed := _pool.max_charges != _data.max_charges
	_pool.max_charges = _data.max_charges
	if _pool.recharge(delta, _data.recharge_time) or max_changed:
		_notify()


func can_spend(cost: float) -> bool:
	return _pool.can_spend(cost)


## Gasta [param cost] cargas si las hay. Devuelve si las gastó.
func spend(cost: float) -> bool:
	if not _pool.spend(cost):
		return false
	_notify()
	return true


func get_charges() -> float:
	return _pool.charges


func get_max_charges() -> int:
	return _pool.max_charges


func _notify() -> void:
	changed.emit(_pool.charges, _pool.max_charges)
	EventBus.player_stamina_changed.emit(_pool.charges, _pool.max_charges)
