class_name Leaderboard
extends RefCounted
## Clasificación local de partidas: las mejores [member max_entries], ordenadas por enemigos
## derrotados (a igualdad, primero las victorias y luego las más largas). Se guarda en un
## [ConfigFile] ([method write_to], [method read_from]); la carga y la guarda [code]Save[/code].

const SECTION := "leaderboard"
const KEY := "runs"

## Partidas que guarda como mucho.
var max_entries: int = 0

var _entries: Array[RunRecord] = []


func _init(size: int) -> void:
	max_entries = size


## Añade [param record] en su sitio (si entra entre las mejores). Devuelve su puesto (desde 0), o
## −1 si no entra.
func add(record: RunRecord) -> int:
	_entries.append(record)
	_entries.sort_custom(_better)
	if _entries.size() > max_entries:
		_entries.resize(max_entries)
	return _entries.find(record)


## Las partidas, de la mejor a la peor.
func get_entries() -> Array[RunRecord]:
	return _entries.duplicate()


func write_to(config: ConfigFile) -> void:
	var runs: Array[Dictionary] = []
	for record: RunRecord in _entries:
		runs.append(record.to_dict())
	config.set_value(SECTION, KEY, runs)


## Lee las partidas guardadas en [param config] (lo que no sea una partida se ignora).
func read_from(config: ConfigFile) -> void:
	_entries.clear()
	var runs: Variant = config.get_value(SECTION, KEY, [])
	if not runs is Array:
		return
	for run: Variant in runs:
		if run is Dictionary:
			var data: Dictionary = run
			_entries.append(RunRecord.from_dict(data))
	_entries.sort_custom(_better)
	if _entries.size() > max_entries:
		_entries.resize(max_entries)


static func _better(a: RunRecord, b: RunRecord) -> bool:
	if a.kills != b.kills:
		return a.kills > b.kills
	if a.won != b.won:
		return a.won
	return a.seconds > b.seconds
