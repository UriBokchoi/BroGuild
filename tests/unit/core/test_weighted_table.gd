extends GutTest
## WeightedTable: elige según los pesos (con semilla, reproducible), nunca una entrada de peso 0 y,
## sin pesos, nada.

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


func _entry(weight: float) -> WeightedEntry:
	var entry := WeightedEntry.new()
	entry.weight = weight
	return entry


func _table(entries: Array[WeightedEntry]) -> WeightedTable:
	var table := WeightedTable.new()
	table.entries = entries
	return table
