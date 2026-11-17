extends GutTest
## Armas de data/weapons: cada una tiene identificador único, nombre y descripción traducidos,
## icono, una escena que es un Weapon, stats de nivel 1, nivel máximo 10 y varias stats que mejorar
## que existen; las que disparan proyectiles pueden mejorar su velocidad.

const WEAPONS_DIR := "res://data/weapons"
const STRINGS_PATH := "res://data/i18n/strings.csv"
## Nivel máximo de las armas (GDD §6).
const MAX_LEVEL := 10

var _keys := PackedStringArray()
var _weapons: Array[WeaponData] = []


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line.is_empty():
			_keys.append(line[0])
	_weapons.assign(ResourceDir.load_all(WEAPONS_DIR, WeaponData))


func test_there_is_a_sword() -> void:
	assert_true(_weapons.any(func(weapon: WeaponData) -> bool: return weapon.id == &"sword"))


func test_ids_are_unique_and_texts_translated() -> void:
	var ids: Array[StringName] = []
	for weapon: WeaponData in _weapons:
		assert_false(weapon.id.is_empty(), "%s: sin id" % weapon.resource_path)
		assert_does_not_have(ids, weapon.id, "id repetido: %s" % weapon.id)
		ids.append(weapon.id)
		assert_has(_keys, String(weapon.name_key), "%s: falta su nombre" % weapon.id)
		assert_has(_keys, String(weapon.description_key), "%s: falta su descripción" % weapon.id)
		assert_not_null(weapon.icon, "%s: sin icono" % weapon.id)


func test_each_weapon_has_a_weapon_scene_and_stats() -> void:
	for weapon: WeaponData in _weapons:
		assert_not_null(weapon.stats, "%s: sin stats" % weapon.id)
		var node := weapon.scene.instantiate()
		assert_true(node is Weapon, "%s: su escena no es un Weapon" % weapon.id)
		node.free()


func test_upgrades_touch_existing_stats_up_to_level_10() -> void:
	for weapon: WeaponData in _weapons:
		assert_eq(weapon.max_level(), MAX_LEVEL, "%s: nivel máximo" % weapon.id)
		assert_gt(weapon.upgrade_stats.size(), 1, "%s: varias stats que mejorar" % weapon.id)
		var block := StatBlock.new()
		block.define_from_resource(weapon.stats)
		for upgrade_stat: UpgradeStat in weapon.upgrade_stats:
			assert_true(block.has_stat(upgrade_stat.stat), "%s: «%s» no es una stat" % [weapon.id, upgrade_stat.stat])


func test_projectile_weapons_can_speed_up_their_projectiles() -> void:
	for weapon: WeaponData in _weapons:
		if not weapon.stats is ProjectileStats:
			continue
		var faster := weapon.upgrade_stats.any(
			func(upgrade_stat: UpgradeStat) -> bool: return upgrade_stat.stat == &"projectile_speed"
		)
		assert_true(faster, "%s: sin mejora de velocidad de proyectil" % weapon.id)
