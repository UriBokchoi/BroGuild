class_name RunRecord
extends RefCounted
## Una partida acabada, para la clasificación ([Leaderboard]): con qué personaje y en qué nivel,
## enemigos y élites derrotados, tiempo, nivel alcanzado, si se pasó el nivel y cuándo fue. Se
## guarda como un diccionario ([method to_dict], [method from_dict]).

var character_id: StringName = &""
## Clave del nombre del personaje (vacía si no se sabe).
var character_name_key: StringName = &""
## Clave del nombre del nivel (el mapa; vacía si no se sabe).
var level_name_key: StringName = &""
var kills: int = 0
var elite_kills: int = 0
var seconds: float = 0.0
## Nivel del jugador al acabar.
var player_level: int = 1
var won: bool = false
## Cuándo acabó (segundos desde 1970, [method Time.get_unix_time_from_system]).
var finished_at: float = 0.0


## La partida apuntada en [param stats], con [param character] en [param level].
static func create(stats: RunStats, character: CharacterData, level: LevelData) -> RunRecord:
	var record := RunRecord.new()
	if character:
		record.character_id = StringName(character.resource_path.get_file().get_basename())
		record.character_name_key = character.name_key
	if level:
		record.level_name_key = level.name_key
	record.kills = stats.kills
	record.elite_kills = stats.elite_kills
	record.seconds = stats.seconds
	record.player_level = stats.level
	record.won = stats.won
	record.finished_at = Time.get_unix_time_from_system()
	return record


func to_dict() -> Dictionary:
	return {
		"character_id": String(character_id),
		"character_name_key": String(character_name_key),
		"level_name_key": String(level_name_key),
		"kills": kills,
		"elite_kills": elite_kills,
		"seconds": seconds,
		"player_level": player_level,
		"won": won,
		"finished_at": finished_at,
	}


## La partida guardada en [param data]; lo que falte (o no sea del tipo que toca) se queda en su
## valor de serie.
static func from_dict(data: Dictionary) -> RunRecord:
	var record := RunRecord.new()
	record.character_id = StringName(str(data.get("character_id", "")))
	record.character_name_key = StringName(str(data.get("character_name_key", "")))
	record.level_name_key = StringName(str(data.get("level_name_key", "")))
	record.kills = roundi(_number(data, "kills", record.kills))
	record.elite_kills = roundi(_number(data, "elite_kills", record.elite_kills))
	record.seconds = _number(data, "seconds", record.seconds)
	record.player_level = roundi(_number(data, "player_level", record.player_level))
	var saved_won: Variant = data.get("won", record.won)
	record.won = saved_won as bool if saved_won is bool else record.won
	record.finished_at = _number(data, "finished_at", record.finished_at)
	return record


## El número de [param key] en [param data], o [param fallback] si no hay o no es un número.
static func _number(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	if value is int:
		return float(value as int)
	if value is float:
		return value as float
	return fallback
