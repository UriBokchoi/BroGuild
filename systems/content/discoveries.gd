class_name Discoveries
extends RefCounted
## Lo que el jugador ha descubierto entre partidas, por tipo de contenido (el id de su
## [ContentCategory]) y entrada (su id). Se guarda en un [ConfigFile] ([method write_to],
## [method read_from]); lo carga y lo guarda [code]Save[/code].

const SECTION := "archive"

var _found: Dictionary[StringName, Dictionary] = {}


## Apunta [param id] en [param category]. Devuelve si era nuevo.
func discover(category: StringName, id: StringName) -> bool:
	if category.is_empty() or id.is_empty() or has(category, id):
		return false
	if not _found.has(category):
		_found[category] = {}
	_found[category][id] = true
	return true


func has(category: StringName, id: StringName) -> bool:
	return _found.has(category) and _found[category].has(id)


## Cuántas entradas de [param category] se han descubierto.
func count(category: StringName) -> int:
	return _found[category].size() if _found.has(category) else 0


func write_to(config: ConfigFile) -> void:
	for category: StringName in _found:
		var ids := PackedStringArray()
		for id: Variant in _found[category]:
			ids.append(str(id))
		config.set_value(SECTION, String(category), ids)


## Lee lo guardado en [param config] (lo que no sea una lista de ids se ignora).
func read_from(config: ConfigFile) -> void:
	_found.clear()
	if not config.has_section(SECTION):
		return
	for key: String in config.get_section_keys(SECTION):
		var ids: Variant = config.get_value(SECTION, key)
		if not (ids is PackedStringArray or ids is Array):
			continue
		for id: Variant in ids:
			if id is String or id is StringName:
				discover(StringName(key), StringName(str(id)))
