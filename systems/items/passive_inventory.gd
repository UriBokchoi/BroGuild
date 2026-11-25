class_name PassiveInventory
extends Node
## Objetos pasivos que lleva el jugador ([PassiveItemData]) y cuántas copias de cada uno, en el
## orden en que los consiguió. Cada copia aplica sus modificadores a las stats con su propio
## origen: así se acumulan y se puede quitar una sola.

## Cambió cuántas copias lleva de [param item] ([param count] 0 = ya no lo lleva).
signal item_changed(item: PassiveItemData, count: int)

## Stats que cambian los objetos (las del jugador).
@export var stats: StatsComponent

var _items: Array[PassiveItemData] = []
## Origen de los modificadores de cada copia (por id), de la primera a la última.
var _copies: Dictionary[StringName, Array] = {}


## Añade una copia de [param item]: suma otra vez sus modificadores.
func add(item: PassiveItemData) -> void:
	if not _copies.has(item.id):
		_items.append(item)
		_copies[item.id] = []
	var copy := RefCounted.new()
	for modifier: StatModifier in item.stat_modifiers:
		stats.add_modifier(modifier, copy)
	_copies[item.id].append(copy)
	item_changed.emit(item, count(item))


## Quita la última copia de [param item] (si lleva alguna).
func remove(item: PassiveItemData) -> void:
	if not _copies.has(item.id):
		return
	var copy: RefCounted = _copies[item.id].pop_back()
	stats.remove_modifiers_from(copy)
	if _copies[item.id].is_empty():
		_copies.erase(item.id)
		_items = _items.filter(func(owned: PassiveItemData) -> bool: return owned.id != item.id)
	item_changed.emit(item, count(item))


## Copias que lleva de [param item].
func count(item: PassiveItemData) -> int:
	var copies: Array = _copies.get(item.id, [])
	return copies.size()


## Objetos distintos que lleva, en el orden en que los consiguió.
func get_items() -> Array[PassiveItemData]:
	return _items.duplicate()


## Los efectos al golpear de los objetos que lleva, con cuántas copias cuenta cada uno (su
## probabilidad se multiplica por ellas).
func on_hit_effects() -> Dictionary[OnHitEffect, int]:
	var effects: Dictionary[OnHitEffect, int] = {}
	for item: PassiveItemData in _items:
		for effect: OnHitEffect in item.on_hit:
			effects[effect] = effects.get(effect, 0) + count(item)
	return effects


## Copias que lleva en total.
func total() -> int:
	var copies := 0
	for owned: Array in _copies.values():
		copies += owned.size()
	return copies
