extends GutTest
## Niveles de data/levels: están el Brosque (jugable), la Torre del Mago y la Mazmorra (próximamente,
## sin escena); cada uno con id único y nombre traducido.

const LEVELS_DIR := "res://data/levels"
const STRINGS_PATH := "res://data/i18n/strings.csv"

var _keys := PackedStringArray()
var _levels: Array[LevelData] = []


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line.is_empty():
			_keys.append(line[0])
	_levels.assign(ResourceDir.load_all(LEVELS_DIR, LevelData))


func test_every_level_is_complete() -> void:
	var ids: Array[StringName] = []
	for level: LevelData in _levels:
		assert_does_not_have(ids, level.id, "id repetido: %s" % level.id)
		ids.append(level.id)
		assert_has(_keys, String(level.name_key), "%s: falta su nombre" % level.id)


func test_the_brosque_is_playable_and_the_others_are_coming_soon() -> void:
	var ids: Array[StringName] = []
	for level: LevelData in _levels:
		ids.append(level.id)
		assert_eq(level.is_available(), level.id == &"brosque", "%s: ¿se puede jugar?" % level.id)
	for id: StringName in [&"brosque", &"wizard_tower", &"dungeon"]:
		assert_has(ids, id)
