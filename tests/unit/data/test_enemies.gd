extends GutTest
## Enemigos de data/enemies: cada EnemyData tiene identificador único, nombre y descripción
## traducidos, una escena que es un Enemy y stats de vida y de enemigo. Sus armas apuntan solo al
## jugador y no están entre las del jugador.

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


func test_there_are_a_swarmer_and_a_shooter() -> void:
	assert_true(_enemies.any(func(enemy: EnemyData) -> bool: return enemy.id == &"swarmer"))
	assert_true(_enemies.any(func(enemy: EnemyData) -> bool: return enemy.id == &"shooter"))


func test_enemy_weapons_aim_only_at_the_player() -> void:
	var player_hurtbox := PhysicsLayers.mask(PhysicsLayers.PLAYER_HURTBOX)
	for enemy: EnemyData in _enemies:
		for weapon_data: WeaponData in enemy.weapons:
			var label := "%s/%s" % [enemy.id, weapon_data.id]
			assert_not_null(weapon_data.stats, "%s: sin stats" % label)
			assert_has(_keys, String(weapon_data.name_key), "%s: falta su nombre" % label)
			var in_player_dir := weapon_data.resource_path.begins_with("res://data/weapons/")
			assert_false(in_player_dir, "%s: no debe salir en la armería ni al subir de nivel" % label)
			var weapon := weapon_data.scene.instantiate() as Weapon
			if weapon == null:
				fail_test("%s: su escena no es un Weapon" % label)
				continue
			assert_eq(weapon.target_mask, player_hurtbox, "%s: apunta al jugador" % label)
			var shooter := weapon as ProjectileWeapon
			if shooter:
				var projectile := shooter.projectile_scene.instantiate() as Projectile
				assert_eq(projectile.hit_mask & ~PhysicsLayers.mask(PhysicsLayers.WORLD), player_hurtbox, "%s: solo da al jugador" % label)
				projectile.free()
			weapon.free()


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
