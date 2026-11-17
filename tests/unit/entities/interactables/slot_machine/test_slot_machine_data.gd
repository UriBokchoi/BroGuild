extends GutTest
## SlotMachineData: el coste sube con la dificultad y con cada uso; tres iguales dan el jackpot de su
## símbolo, dos iguales su pareja y ninguno nada; cada rodillo saca un símbolo de la tabla, igual con
## la misma semilla.

const DATA := preload("res://data/slots/slot_machine.tres")

var _coin: SlotSymbol
var _skull: SlotSymbol
var _star: SlotSymbol


func before_each() -> void:
	_coin = _symbol()
	_skull = _symbol()
	_star = _symbol()


func test_cost_grows_with_difficulty_and_uses() -> void:
	var data := SlotMachineData.new()
	data.base_cost = 10.0
	data.cost_per_difficulty = 5.0
	data.cost_growth = 2.0
	assert_eq(data.cost_at(0.0, 0), 10)
	assert_eq(data.cost_at(2.0, 0), 20)
	assert_eq(data.cost_at(2.0, 2), 80, "×2 por cada uso")


func test_three_of_a_kind_is_the_jackpot() -> void:
	assert_same(SlotMachineData.evaluate(_results([_coin, _coin, _coin])), _coin.jackpot)


func test_two_of_a_kind_is_the_pair() -> void:
	assert_same(SlotMachineData.evaluate(_results([_skull, _coin, _skull])), _skull.pair)


func test_all_different_is_nothing() -> void:
	assert_null(SlotMachineData.evaluate(_results([_coin, _skull, _star])))


func test_rolls_one_symbol_per_reel_reproducibly() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var first := DATA.roll(rng)
	assert_eq(first.size(), DATA.reels)
	rng.seed = 4
	assert_eq(DATA.roll(rng), first)


func test_the_data_symbols_are_complete() -> void:
	assert_gt(DATA.symbols.total_weight(), 0.0)
	for entry: WeightedEntry in DATA.symbols.entries:
		var symbol := entry as SlotSymbol
		assert_not_null(symbol.icon)
		for outcome: SlotOutcome in [symbol.pair, symbol.jackpot]:
			assert_not_null(outcome)
			assert_false(outcome.reward.is_empty())
			assert_false(outcome.text_key.is_empty())


func _symbol() -> SlotSymbol:
	var symbol := SlotSymbol.new()
	symbol.weight = 1.0
	symbol.pair = SlotOutcome.new()
	symbol.jackpot = SlotOutcome.new()
	return symbol


func _results(symbols: Array) -> Array[SlotSymbol]:
	var results: Array[SlotSymbol] = []
	for symbol: SlotSymbol in symbols:
		results.append(symbol)
	return results
