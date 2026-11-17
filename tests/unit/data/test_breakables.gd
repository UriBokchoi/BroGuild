extends GutTest
## Rompibles de data/breakables: están la calavera (experiencia) y la bolsita (oro), y cada uno
## suelta algo, con valor y en al menos un trozo, y más cuanto mayor es la dificultad.

const BREAKABLES_DIR := "res://data/breakables"
const XP_GEM := preload("res://data/pickups/xp_gem.tres")
const GOLD_COIN := preload("res://data/pickups/gold_coin.tres")

var _breakables: Dictionary[String, BreakableData] = {}


func before_all() -> void:
	for resource: Resource in ResourceDir.load_all(BREAKABLES_DIR, BreakableData):
		_breakables[resource.resource_path.get_file().get_basename()] = resource as BreakableData


func test_skulls_give_experience_and_pouches_gold() -> void:
	assert_same(_breakables["skull"].reward, XP_GEM)
	assert_same(_breakables["pouch"].reward, GOLD_COIN)


func test_every_breakable_drops_something() -> void:
	for id: String in _breakables:
		var data := _breakables[id]
		assert_not_null(data.reward, "%s: no suelta nada" % id)
		assert_gt(data.amount, 0.0, "%s: sin valor" % id)
		assert_gte(data.pieces, 1, "%s: sin trozos" % id)


func test_more_difficulty_more_loot() -> void:
	for id: String in _breakables:
		var data := _breakables[id]
		assert_gt(data.amount_per_difficulty, 0.0, "%s: no sube con la dificultad" % id)
		assert_almost_eq(data.amount_at(10.0), data.amount + data.amount_per_difficulty * 10.0, 0.001)
