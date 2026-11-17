class_name RuneInventory
extends Node
## Runas que lleva el jugador y su nivel. Aplica los modificadores de cada nivel a sus stats (se
## acumulan) y los quita al bajar de nivel o al quitar la runa.

## Cambió el nivel de [param rune] ([param level] 0 = quitada).
signal rune_changed(rune: RuneData, level: int)

## Stats que mejoran las runas (las del jugador).
@export var stats: StatsComponent

var _runes: Array[RuneData] = []
var _levels: Dictionary[StringName, int] = {}


## Añade [param rune] a nivel 1. Si ya la lleva, no hace nada y devuelve [code]false[/code].
func add(rune: RuneData) -> bool:
	if has(rune):
		return false
	set_level(rune, 1)
	return true


## Pone [param rune] a [param level] (de 0 a su máximo; 0 la quita).
func set_level(rune: RuneData, level: int) -> void:
	level = clampi(level, 0, rune.max_level())
	if level == get_level(rune):
		return
	for level_set: StatModifierSet in rune.levels:
		stats.remove_modifiers_from(level_set)
	for index: int in level:
		for modifier: StatModifier in rune.levels[index].stat_modifiers:
			stats.add_modifier(modifier, rune.levels[index])
	_store(rune, level)
	rune_changed.emit(rune, level)


## Quita [param rune] y sus mejoras.
func remove(rune: RuneData) -> void:
	set_level(rune, 0)


## Nivel de [param rune] (0 si no la lleva).
func get_level(rune: RuneData) -> int:
	return _levels.get(rune.id, 0)


func has(rune: RuneData) -> bool:
	return get_level(rune) > 0


## Runas que lleva, en el orden en que las consiguió.
func get_runes() -> Array[RuneData]:
	return _runes.duplicate()


func _store(rune: RuneData, level: int) -> void:
	if level == 0:
		_levels.erase(rune.id)
		_runes = _runes.filter(func(owned: RuneData) -> bool: return owned.id != rune.id)
		return
	if not _levels.has(rune.id):
		_runes.append(rune)
	_levels[rune.id] = level
