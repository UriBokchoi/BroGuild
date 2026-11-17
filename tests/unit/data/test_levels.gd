extends GutTest
## Niveles de data/levels: está el Brosque y cada uno tiene id único, nombre traducido y escena.

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


func test_the_brosque_exists() -> void:
	assert_true(_levels.any(func(level: LevelData) -> bool: return level.id == &"brosque"))


func test_every_level_is_complete() -> void:
	var ids: Array[StringName] = []
	for level: LevelData in _levels:
		assert_does_not_have(ids, level.id, "id repetido: %s" % level.id)
		ids.append(level.id)
		assert_has(_keys, String(level.name_key), "%s: falta su nombre" % level.id)
		assert_not_null(level.scene, "%s: sin escena" % level.id)
