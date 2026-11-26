extends GutTest
## Las mejoras permanentes de data/meta/upgrades.tres: ids distintos, nombre y descripción traducidos,
## icono, las stats que cambian existen en el jugador, un precio por nivel (positivo) y cada nivel
## suma más que el anterior. Están las que pidió el diseñador.

const UPGRADES := preload("res://data/meta/upgrades.tres")
const STRINGS_PATH := "res://data/i18n/strings.csv"
const PlayerScene := preload("res://entities/player/player.tscn")

var _keys := PackedStringArray()


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line.is_empty():
			_keys.append(line[0])


func test_the_requested_upgrades_exist() -> void:
	for id: StringName in [&"damage", &"area", &"crit_chance", &"max_health", &"armor", &"speed",
			&"luck", &"difficulty", &"greed", &"weapon_slots", &"rune_slots", &"weapon_level",
			&"rune_level", &"skips_bans"]:
		assert_not_null(UPGRADES.find(id), "falta «%s»" % id)


func test_every_upgrade_is_complete() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var ids: Array[StringName] = []
	for upgrade: MetaUpgradeData in UPGRADES.upgrades:
		var label := String(upgrade.id)
		assert_false(ids.has(upgrade.id), "%s: id repetido" % label)
		ids.append(upgrade.id)
		for key: StringName in [upgrade.name_key, upgrade.description_key, upgrade.value_key]:
			assert_has(_keys, String(key), "%s: falta «%s»" % [label, key])
		assert_not_null(upgrade.icon, "%s: sin icono" % label)
		assert_false(upgrade.stats.is_empty(), "%s: no cambia nada" % label)
		for stat: StringName in upgrade.stats:
			assert_true(player.stats.has_stat(stat), "%s: el jugador no tiene «%s»" % [label, stat])
		assert_eq(upgrade.values.size(), upgrade.costs.size(), "%s: un precio por nivel" % label)
		for level: int in range(1, upgrade.max_level() + 1):
			assert_gt(upgrade.cost_of(level), 0, "%s: nivel %d gratis" % [label, level])
			assert_gt(upgrade.value_at(level), upgrade.value_at(level - 1),
				"%s: el nivel %d no suma más" % [label, level])
