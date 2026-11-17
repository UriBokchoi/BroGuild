extends GutTest
## Runas de data/runes: están las cinco iniciales, cada una con id único, nombre y descripción
## traducidos, entre 1 y 5 niveles y modificadores sobre stats que el jugador tiene.

const RUNES_DIR := "res://data/runes"
const STRINGS_PATH := "res://data/i18n/strings.csv"
const PlayerScene := preload("res://entities/player/player.tscn")
## Nivel máximo de partida de las runas (GDD §6).
const MAX_LEVEL := 5

var _keys := PackedStringArray()
var _runes: Array[RuneData] = []


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line.is_empty():
			_keys.append(line[0])
	_runes.assign(ResourceDir.load_all(RUNES_DIR, RuneData))


func test_the_five_starting_runes_exist() -> void:
	var ids: Array[StringName] = []
	for rune: RuneData in _runes:
		ids.append(rune.id)
	for id: StringName in [&"strength", &"amplitude", &"haste", &"vigor", &"multiplicity"]:
		assert_has(ids, id)


func test_ids_are_unique_and_texts_translated() -> void:
	var ids: Array[StringName] = []
	for rune: RuneData in _runes:
		assert_does_not_have(ids, rune.id, "id repetido: %s" % rune.id)
		ids.append(rune.id)
		assert_has(_keys, String(rune.name_key), "%s: falta su nombre" % rune.id)
		assert_has(_keys, String(rune.description_key), "%s: falta su descripción" % rune.id)


func test_levels_change_player_stats() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	for rune: RuneData in _runes:
		assert_between(rune.max_level(), 1, MAX_LEVEL, "%s: nivel máximo" % rune.id)
		for level_set: StatModifierSet in rune.levels:
			for modifier: StatModifier in level_set.stat_modifiers:
				assert_true(player.stats.has_stat(modifier.stat), "%s: «%s» no es una stat" % [rune.id, modifier.stat])
