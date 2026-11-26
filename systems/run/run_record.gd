class_name RunRecord
extends RefCounted
## Una partida acabada, para la clasificación ([Leaderboard]): con qué personaje y en qué nivel (y su
## tier y hasta dónde llegó), enemigos y élites derrotados, tiempo, nivel alcanzado, oro, daño, si se
## pasó el nivel, cuándo fue y la build con la que acabó (armas, runas, objetos y pactos). Se guarda
## como un diccionario ([method to_dict], [method from_dict]); las partidas viejas no tienen build.

var character_id: StringName = &""
## Clave del nombre del personaje (vacía si no se sabe).
var character_name_key: StringName = &""
## Clave del nombre del nivel (el mapa; vacía si no se sabe).
var level_name_key: StringName = &""
## Tier elegido (0: un nivel sin tiers).
var tier: int = 0
## Fase a la que se llegó (su nombre; vacío: un nivel sin tiers).
var stage_key: StringName = &""
var kills: int = 0
var elite_kills: int = 0
var seconds: float = 0.0
## Nivel del jugador al acabar.
var player_level: int = 1
var won: bool = false
## Cuándo acabó (segundos desde 1970, [method Time.get_unix_time_from_system]).
var finished_at: float = 0.0
var gold_earned: float = 0.0
var damage_dealt: float = 0.0
## La build al acabar: armas y runas (id → nivel), objetos (id → copias) y pactos (su nombre).
var weapons: Dictionary[String, int] = {}
var runes: Dictionary[String, int] = {}
var items: Dictionary[String, int] = {}
var pacts: Array[String] = []


## La partida apuntada en [param stats], con [param character] en [param level] (en su tier
## [param chosen_tier], si tiene).
static func create(stats: RunStats, character: CharacterData, level: LevelData, chosen_tier: int = 0) -> RunRecord:
	var record := RunRecord.new()
	if character:
		record.character_id = character.id
		record.character_name_key = character.name_key
	if level:
		record.level_name_key = level.name_key
		if not level.tiers.is_empty():
			record.tier = chosen_tier
	record.kills = stats.kills
	record.elite_kills = stats.elite_kills
	record.seconds = stats.seconds
	record.player_level = stats.level
	record.won = stats.won
	record.stage_key = stats.stage_key
	record.gold_earned = stats.gold_earned
	record.damage_dealt = stats.damage_dealt
	record.finished_at = Time.get_unix_time_from_system()
	return record


## ¿Tiene apuntada la build (las partidas viejas, no)?
func has_build() -> bool:
	return not weapons.is_empty() or not runes.is_empty() or not items.is_empty() or not pacts.is_empty()


func to_dict() -> Dictionary:
	return {
		"character_id": String(character_id),
		"character_name_key": String(character_name_key),
		"level_name_key": String(level_name_key),
		"tier": tier,
		"stage_key": String(stage_key),
		"kills": kills,
		"elite_kills": elite_kills,
		"seconds": seconds,
		"player_level": player_level,
		"won": won,
		"finished_at": finished_at,
		"gold_earned": gold_earned,
		"damage_dealt": damage_dealt,
		"weapons": weapons,
		"runes": runes,
		"items": items,
		"pacts": pacts,
	}


## La partida guardada en [param data]; lo que falte (o no sea del tipo que toca) se queda en su
## valor de serie.
static func from_dict(data: Dictionary) -> RunRecord:
	var record := RunRecord.new()
	record.character_id = StringName(str(data.get("character_id", "")))
	record.character_name_key = StringName(str(data.get("character_name_key", "")))
	record.level_name_key = StringName(str(data.get("level_name_key", "")))
	record.tier = roundi(_number(data, "tier", record.tier))
	record.stage_key = StringName(str(data.get("stage_key", "")))
	record.kills = roundi(_number(data, "kills", record.kills))
	record.elite_kills = roundi(_number(data, "elite_kills", record.elite_kills))
	record.seconds = _number(data, "seconds", record.seconds)
	record.player_level = roundi(_number(data, "player_level", record.player_level))
	var saved_won: Variant = data.get("won", record.won)
	record.won = saved_won as bool if saved_won is bool else record.won
	record.finished_at = _number(data, "finished_at", record.finished_at)
	record.gold_earned = _number(data, "gold_earned", record.gold_earned)
	record.damage_dealt = _number(data, "damage_dealt", record.damage_dealt)
	_read_counts(data.get("weapons"), record.weapons)
	_read_counts(data.get("runes"), record.runes)
	_read_counts(data.get("items"), record.items)
	var saved_pacts: Variant = data.get("pacts")
	if saved_pacts is Array:
		for pact: Variant in saved_pacts as Array:
			record.pacts.append(str(pact))
	return record


## Copia en [param into] los pares id → número de [param saved] (si es un diccionario).
static func _read_counts(saved: Variant, into: Dictionary[String, int]) -> void:
	if not saved is Dictionary:
		return
	var counts: Dictionary = saved
	for key: Variant in counts:
		var value: Variant = counts[key]
		if value is int or value is float:
			into[str(key)] = roundi(value as float)


## El número de [param key] en [param data], o [param fallback] si no hay o no es un número.
static func _number(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	if value is int:
		return float(value as int)
	if value is float:
		return value as float
	return fallback
