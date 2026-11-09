extends GutTest
## Personajes de data/characters: cada uno es un CharacterData con nombre y descripción traducidos
## y sus diferencias apuntan a stats que el jugador tiene.

const CHARACTERS_DIR := "res://data/characters/"
const STRINGS_PATH := "res://data/i18n/strings.csv"
const PlayerScene := preload("res://entities/player/player.tscn")

var _keys := PackedStringArray()


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line.is_empty():
			_keys.append(line[0])


func test_there_is_a_base_character() -> void:
	assert_true(ResourceLoader.exists(CHARACTERS_DIR + "base.tres"))


func test_every_character_is_translated_and_changes_existing_stats() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	for file_name: String in DirAccess.get_files_at(CHARACTERS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var character := load(CHARACTERS_DIR + file_name) as CharacterData
		assert_not_null(character, "%s no es un CharacterData" % file_name)
		assert_has(_keys, String(character.name_key), "%s: falta su nombre" % file_name)
		assert_has(_keys, String(character.description_key), "%s: falta su descripción" % file_name)
		for modifier: StatModifier in character.stat_modifiers:
			assert_true(player.stats.has_stat(modifier.stat), "%s: «%s» no es una stat" % [file_name, modifier.stat])
