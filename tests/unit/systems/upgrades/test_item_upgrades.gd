extends GutTest
## Mejoras con rareza: las rarezas de data/rarities van de común (gris) a mítica (roja), cada vez
## menos probables y más fuertes; una mejora tirada toca tantas stats distintas del objeto como
## diga su rareza (la mítica, todas), elegidas según su peso y con su fuerza; los enteros se redondean y los multiplicadores
## escalan lo que se alejan de 1.

const RARITIES := preload("res://data/rarities/rarities.tres")
const COMMON := preload("res://data/rarities/common.tres")
const MYTHIC := preload("res://data/rarities/mythic.tres")
const SWORD := preload("res://data/weapons/sword.tres")
const ORDER: Array[StringName] = [&"common", &"rare", &"improbable", &"legendary", &"mythic"]

var _rng: RandomNumberGenerator


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 13


func test_five_rarities_rarer_and_stronger_in_order() -> void:
	assert_eq(RARITIES.entries.size(), ORDER.size())
	for index: int in ORDER.size():
		var rarity := RARITIES.entries[index] as Rarity
		assert_eq(rarity.id, ORDER[index])
		if index > 0:
			var previous := RARITIES.entries[index - 1] as Rarity
			assert_lt(rarity.weight, previous.weight, "%s, más rara" % rarity.id)
			assert_gt(rarity.power, previous.power, "%s, más fuerte" % rarity.id)


func test_a_common_upgrade_touches_one_stat() -> void:
	for _roll: int in 20:
		var upgrade := SWORD.roll_upgrade(COMMON, _rng)
		assert_eq(upgrade.stat_modifiers.size(), 1)
		assert_same(upgrade.rarity, COMMON)


func test_a_mythic_upgrade_touches_every_stat_stronger() -> void:
	var upgrade := SWORD.roll_upgrade(MYTHIC, _rng)
	var touched: Array[StringName] = []
	for modifier: StatModifier in upgrade.stat_modifiers:
		assert_does_not_have(touched, modifier.stat, "sin repetir stat")
		touched.append(modifier.stat)
		if modifier.stat == &"damage":
			assert_almost_eq(modifier.value, _common_value(SWORD, &"damage") * MYTHIC.power, 0.001)
	assert_eq(touched.size(), SWORD.upgrade_stats.size())


func test_whole_numbers_are_rounded_and_multipliers_scale_from_one() -> void:
	var projectiles := UpgradeStat.new()
	projectiles.stat = &"projectiles"
	projectiles.value = 1.0
	projectiles.whole_numbers = true
	assert_eq(projectiles.modifier(2.5).value, 3.0)
	assert_eq(projectiles.modifier(0.2).value, 1.0, "nunca menos de 1")
	var cooldown := UpgradeStat.new()
	cooldown.stat = &"cooldown"
	cooldown.kind = StatModifier.Kind.MULTIPLIER
	cooldown.value = 0.92
	assert_almost_eq(cooldown.modifier(2.0).value, 0.84, 0.0001)


func test_each_default_upgrade_is_a_new_one() -> void:
	assert_ne(SWORD.default_upgrade(), SWORD.default_upgrade(), "se pueden quitar por separado")


func test_lighter_stats_come_up_less_often() -> void:
	var rune := RuneData.new()
	rune.upgrade_stats = [_upgrade_stat(&"damage", 1.0), _upgrade_stat(&"area", 0.25), _upgrade_stat(&"luck", 0.0)] as Array[UpgradeStat]
	var picks: Dictionary[StringName, int] = {&"damage": 0, &"area": 0, &"luck": 0}
	for _roll: int in 2000:
		picks[rune.roll_upgrade(COMMON, _rng).stat_modifiers[0].stat] += 1
	assert_between(picks[&"area"], 300, 500, "≈ 20 %: un cuarto de peso")
	assert_eq(picks[&"luck"], 0, "con peso 0, nunca")


## Mejora de [param stat] de una carta común en [param item].
func _common_value(item: ItemData, stat: StringName) -> float:
	for upgrade_stat: UpgradeStat in item.upgrade_stats:
		if upgrade_stat.stat == stat:
			return upgrade_stat.value
	return 0.0


func _upgrade_stat(stat: StringName, weight: float) -> UpgradeStat:
	var upgrade_stat := UpgradeStat.new()
	upgrade_stat.stat = stat
	upgrade_stat.value = 1.0
	upgrade_stat.weight = weight
	return upgrade_stat
