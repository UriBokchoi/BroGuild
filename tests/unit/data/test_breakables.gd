extends GutTest
## Rompibles de data/breakables: están la calavera (experiencia) y la bolsita (oro), y cada uno
## suelta algo, con valor y en al menos un trozo, y más cuanto mayor es la dificultad; élites y
## rompibles multiplican la probabilidad de botín y tiran de una tabla de extras completa (con la
## bebida energética).

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


func test_breakables_and_elites_roll_a_complete_drop_table() -> void:
	var elite := preload("res://data/enemies/elite.tres") as EliteData
	assert_gt(elite.drop_chance_multiplier, 1.0, "el élite suelta más que un enemigo normal")
	_assert_table(elite.drop_table, "elite")
	for id: String in _breakables:
		assert_gt(_breakables[id].drop_chance_multiplier, 1.0, "%s: multiplicador" % id)
		_assert_table(_breakables[id].drop_table, id)


func test_the_power_up_table_has_the_energy_drink() -> void:
	var table := preload("res://data/loot/power_ups.tres") as WeightedTable
	var ids: Array[StringName] = []
	for entry: WeightedEntry in table.entries:
		ids.append((entry as BonusDrop).pickup.id)
	for id: StringName in [&"magnet", &"food", &"bomb", &"energy_drink"]:
		assert_has(ids, id)


func _assert_table(table: WeightedTable, owner_id: String) -> void:
	assert_not_null(table, "%s: sin tabla de extras" % owner_id)
	if table == null:
		return
	assert_gt(table.total_weight(), 0.0, "%s: tabla sin pesos" % owner_id)
	for entry: WeightedEntry in table.entries:
		var bonus := entry as BonusDrop
		assert_not_null(bonus, "%s: entrada que no es un BonusDrop" % owner_id)
		if bonus:
			assert_not_null(bonus.pickup, "%s: extra sin recogible" % owner_id)
			assert_gt(bonus.amount, 0.0, "%s: extra sin valor" % owner_id)
