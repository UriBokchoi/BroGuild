extends GutTest
## BossData: el jefe sale más fuerte con la dificultad (con sus propias curvas) y el premio es mayor
## cuanto antes cae. El del Brosque es el Ent-renador: tres tarjetas, sus textos traducidos y un
## premio de rareza alta.

const BROSQUE := preload("res://data/bosses/brosque.tres")
const COMMON := preload("res://data/rarities/common.tres")
const RARE := preload("res://data/rarities/rare.tres")


func test_it_comes_stronger_with_difficulty() -> void:
	var early := _factor(BROSQUE.scaling_at(0.0), &"max_health")
	var late := _factor(BROSQUE.scaling_at(10.0), &"max_health")
	assert_almost_eq(early, 1.0, 0.001)
	assert_gt(late, early)
	assert_null(BossData.new().scaling_at(5.0), "sin curvas, sin escalado")


func test_the_sooner_the_bigger_the_bonus() -> void:
	assert_gt(BROSQUE.bonus_at(3.0), BROSQUE.bonus_at(8.0))
	assert_almost_eq(BROSQUE.bonus_at(10.0), 1.0, 0.01, "en el minuto 10, sin extra")
	assert_almost_eq(BossData.new().bonus_at(2.0), 1.0, 0.001, "sin curva, ×1")


func test_the_brosque_boss_is_the_ent_trainer() -> void:
	assert_eq(BROSQUE.enemy.id, &"ent_trainer")
	assert_eq(BROSQUE.keys_needed, 3)
	var keys: Array[StringName] = BROSQUE.arrival_keys.duplicate()
	keys.append(BROSQUE.victory_key)
	keys.append(BROSQUE.enemy.name_key)
	for key: StringName in keys:
		assert_ne(TranslationServer.translate(key), key, "«%s» sin traducir" % key)


func test_the_reward_is_of_a_high_rarity() -> void:
	var pool := BROSQUE.reward_items
	assert_false(pool.rarities.entries.has(COMMON))
	assert_false(pool.rarities.entries.has(RARE))
	var catalog := pool.load_catalog()
	assert_gt(catalog.size(), 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for _roll: int in 200:
		var item := pool.roll(catalog, 0.0, rng)
		assert_false(item.rarity.id in [COMMON.id, RARE.id], "«%s» es %s" % [item.id, item.rarity.id])


## El multiplicador de [param stat] en [param modifiers] (1 si no está).
func _factor(modifiers: StatModifierSet, stat: StringName) -> float:
	for modifier: StatModifier in modifiers.stat_modifiers:
		if modifier.stat == stat:
			return modifier.value
	return 1.0
