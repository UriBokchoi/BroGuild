extends GutTest
## Enemigos de data/enemies: cada EnemyData tiene identificador único, nombre y descripción
## traducidos, una escena que es un Enemy y stats de vida y de enemigo.

const ENEMIES_DIR := "res://data/enemies"
const STRINGS_PATH := "res://data/i18n/strings.csv"

var _keys := PackedStringArray()
var _enemies: Array[EnemyData] = []


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line.is_empty():
			_keys.append(line[0])
	_enemies.assign(ResourceDir.load_all(ENEMIES_DIR, EnemyData))


func test_there_is_a_swarmer() -> void:
	assert_true(_enemies.any(func(enemy: EnemyData) -> bool: return enemy.id == &"swarmer"))


func test_ids_are_unique_and_texts_translated() -> void:
	var ids: Array[StringName] = []
	for enemy: EnemyData in _enemies:
		assert_false(enemy.id.is_empty(), "%s: sin id" % enemy.resource_path)
		assert_does_not_have(ids, enemy.id, "id repetido: %s" % enemy.id)
		ids.append(enemy.id)
		assert_has(_keys, String(enemy.name_key), "%s: falta su nombre" % enemy.id)
		assert_has(_keys, String(enemy.description_key), "%s: falta su descripción" % enemy.id)


func test_each_enemy_has_an_enemy_scene_and_its_stats() -> void:
	for enemy: EnemyData in _enemies:
		var node := enemy.scene.instantiate()
		assert_true(node is Enemy, "%s: su escena no es un Enemy" % enemy.id)
		node.free()
		var has_health := enemy.stat_sources.any(func(source: Resource) -> bool: return source is HealthData)
		var has_stats := enemy.stat_sources.any(func(source: Resource) -> bool: return source is EnemyStats)
		assert_true(has_health and has_stats, "%s: le falta HealthData o EnemyStats" % enemy.id)
