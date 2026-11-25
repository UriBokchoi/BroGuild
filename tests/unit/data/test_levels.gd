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


func test_the_brosque_tiers_match_its_scene_and_have_their_texts() -> void:
	var brosque: LevelData = load("res://data/levels/brosque.tres")
	assert_eq(brosque.tiers.size(), 3, "verano, otoño e invierno")
	var level := brosque.scene.instantiate()
	var stages := level.get_node(^"Stages") as LevelStages
	assert_eq(stages.tiers, brosque.tiers, "los mismos tiers en los datos y en la escena")
	assert_not_null(stages.final_stage, "tras el último tier, la arena final")
	var all: Array[StageData] = brosque.tiers.duplicate()
	all.append(stages.final_stage)
	for stage: StageData in all:
		assert_has(_keys, String(stage.name_key), "%s: falta su nombre" % stage.resource_path)
		var map := stage.map.instantiate()
		assert_true(map is LevelMap, "%s: su mapa es un LevelMap" % stage.resource_path)
		map.free()
	for stage: StageData in brosque.tiers:
		assert_has(_keys, String(stage.goal_key), "%s: falta su objetivo" % stage.resource_path)
	assert_lt(brosque.tiers[0].difficulty, brosque.tiers[1].difficulty, "cada tier, más difícil")
	assert_lt(brosque.tiers[1].difficulty, brosque.tiers[2].difficulty)
	level.free()
