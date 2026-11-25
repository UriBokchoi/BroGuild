class_name LevelProgress
extends RefCounted
## Hasta qué tier se ha superado cada nivel: el tier 1 siempre está abierto y superar uno abre el
## siguiente. Se guarda en un [ConfigFile] ([method write_to], [method read_from]); la carga y la
## guarda Save.

const SECTION := "completed_tiers"

## Tier más alto superado de cada nivel (por su id).
var _completed: Dictionary[StringName, int] = {}


## ¿Se puede jugar el tier [param tier] de [param level_id]?
func is_unlocked(level_id: StringName, tier: int) -> bool:
	return tier <= 1 or completed(level_id) >= tier - 1


## Tier más alto superado de [param level_id] (0: ninguno).
func completed(level_id: StringName) -> int:
	return _completed.get(level_id, 0)


## Apunta que se superó el tier [param tier] de [param level_id]. Devuelve si es nuevo (abre otro).
func complete(level_id: StringName, tier: int) -> bool:
	if tier <= completed(level_id):
		return false
	_completed[level_id] = tier
	return true


func write_to(config: ConfigFile) -> void:
	for level_id: StringName in _completed:
		config.set_value(SECTION, String(level_id), _completed[level_id])


func read_from(config: ConfigFile) -> void:
	_completed.clear()
	if not config.has_section(SECTION):
		return
	for key: String in config.get_section_keys(SECTION):
		var value: Variant = config.get_value(SECTION, key, 0)
		if value is int:
			_completed[StringName(key)] = value as int
