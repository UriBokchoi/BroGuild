class_name RuneInventory
extends Node
## Runas que lleva el jugador y sus mejoras. Su nivel es cuántas lleva: al conseguirla, la estándar
## ([method ItemData.default_upgrade]); cada subida de nivel, una tirada con rareza. Aplica los
## modificadores de cada mejora a sus stats (se acumulan) y los quita al bajar de nivel o al quitar
## la runa.

## Cambió el nivel de [param rune] ([param level] 0 = quitada).
signal rune_changed(rune: RuneData, level: int)

## Stats que mejoran las runas (las del jugador).
@export var stats: StatsComponent

var _runes: Array[RuneData] = []
## Mejoras de cada runa (por id), de la primera a la última.
var _upgrades: Dictionary[StringName, Array] = {}


## Añade [param rune] a nivel 1. Si ya la lleva, no hace nada y devuelve [code]false[/code].
func add(rune: RuneData) -> bool:
	if has(rune):
		return false
	_runes.append(rune)
	_upgrades[rune.id] = []
	_apply(rune, rune.default_upgrade())
	return true


## Le suma a [param rune] la mejora [param extra] (un nivel más). Si no la lleva o está al
## máximo, no hace nada.
func upgrade(rune: RuneData, extra: ItemUpgrade) -> void:
	if has(rune) and get_level(rune) < rune.max_level_with(stats):
		_apply(rune, extra)


## Pone [param rune] a [param level] (de 0 a su máximo; 0 la quita): para subir, suma mejoras
## estándar (la armería de práctica); para bajar, quita las últimas.
func set_level(rune: RuneData, level: int) -> void:
	level = clampi(level, 0, rune.max_level_with(stats))
	if level > 0 and not has(rune):
		add(rune)
	while has(rune) and get_level(rune) < level:
		_apply(rune, rune.default_upgrade())
	while has(rune) and get_level(rune) > level:
		_remove_last(rune)


## Quita [param rune] y sus mejoras.
func remove(rune: RuneData) -> void:
	set_level(rune, 0)


## Nivel de [param rune] (0 si no la lleva).
func get_level(rune: RuneData) -> int:
	return _upgrades[rune.id].size() if _upgrades.has(rune.id) else 0


func has(rune: RuneData) -> bool:
	return get_level(rune) > 0


## Runas que lleva, en el orden en que las consiguió.
func get_runes() -> Array[RuneData]:
	return _runes.duplicate()


func _apply(rune: RuneData, extra: ItemUpgrade) -> void:
	for modifier: StatModifier in extra.stat_modifiers:
		stats.add_modifier(modifier, extra)
	_upgrades[rune.id].append(extra)
	rune_changed.emit(rune, get_level(rune))


func _remove_last(rune: RuneData) -> void:
	var last: ItemUpgrade = _upgrades[rune.id].pop_back()
	stats.remove_modifiers_from(last)
	if _upgrades[rune.id].is_empty():
		_upgrades.erase(rune.id)
		_runes = _runes.filter(func(owned: RuneData) -> bool: return owned.id != rune.id)
	rune_changed.emit(rune, get_level(rune))
