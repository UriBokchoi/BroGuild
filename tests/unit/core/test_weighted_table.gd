extends GutTest
## WeightedTable: elige según los pesos (con semilla, reproducible), nunca una entrada de peso 0 y,
## sin pesos, nada. La Suerte sube las entradas que escalan con ella y sin Suerte todo queda igual.

var _rng: RandomNumberGenerator


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 21


func test_weights_decide_how_often() -> void:
	var rare := _entry(1.0)
	var common := _entry(3.0)
	var table := _table([rare, common] as Array[WeightedEntry])
	var commons := 0
	for _pick: int in 4000:
		if table.pick(_rng) == common:
			commons += 1
	assert_between(commons, 2800, 3200, "≈ 3 de cada 4")


func test_never_picks_a_zero_weight() -> void:
	var never := _entry(0.0)
	var table := _table([never, _entry(1.0)] as Array[WeightedEntry])
	for _pick: int in 200:
		assert_ne(table.pick(_rng), never)


func test_no_weights_gives_null() -> void:
	assert_null(_table([_entry(0.0)] as Array[WeightedEntry]).pick(_rng))
	assert_null(_table([] as Array[WeightedEntry]).pick(_rng))


func test_same_seed_same_picks() -> void:
	var table := _table([_entry(1.0), _entry(2.0), _entry(3.0)] as Array[WeightedEntry])
	var again := RandomNumberGenerator.new()
	again.seed = 21
	for _pick: int in 50:
		assert_same(table.pick(_rng), table.pick(again))


func test_without_luck_nothing_changes() -> void:
	var table := _table([_entry(1.0, 50.0), _entry(2.0), _entry(3.0, 10.0)] as Array[WeightedEntry])
	var again := RandomNumberGenerator.new()
	again.seed = 21
	for _pick: int in 50:
		assert_same(table.pick(_rng, 0.0), table.pick(again))


func test_luck_raises_the_entries_that_scale_with_it() -> void:
	var good := _entry(1.0, 10.0)
	var plain := _entry(3.0)
	var table := _table([good, plain] as Array[WeightedEntry])
	assert_almost_eq(table.chance(good), 0.25, 0.001)
	assert_almost_eq(good.weight_with_luck(20.0), 3.0, 0.001, "+10 % de su peso por punto")
	assert_almost_eq(plain.weight_with_luck(20.0), 3.0, 0.001, "sin escala, igual")
	assert_almost_eq(table.chance(good, 20.0), 0.5, 0.001)
	var goods := 0
	for _pick: int in 4000:
		if table.pick(_rng, 20.0) == good:
			goods += 1
	assert_between(goods, 1800, 2200, "≈ la mitad con 20 de Suerte")


func test_chances_add_up_to_one() -> void:
	var entries: Array[WeightedEntry] = [_entry(1.0, 5.0), _entry(2.0), _entry(0.0, 50.0)]
	var table := _table(entries)
	var total := 0.0
	for entry: WeightedEntry in entries:
		total += table.chance(entry, 30.0)
	assert_almost_eq(total, 1.0, 0.001)
	assert_eq(table.chance(entries[2], 30.0), 0.0, "sin peso, ni con Suerte")
	assert_eq(table.chance(_entry(1.0), 30.0), 0.0, "una que no está en la tabla")


func _entry(weight: float, luck_scaling: float = 0.0) -> WeightedEntry:
	var entry := WeightedEntry.new()
	entry.weight = weight
	entry.luck_scaling = luck_scaling
	return entry


func _table(entries: Array[WeightedEntry]) -> WeightedTable:
	var table := WeightedTable.new()
	table.entries = entries
	return table
