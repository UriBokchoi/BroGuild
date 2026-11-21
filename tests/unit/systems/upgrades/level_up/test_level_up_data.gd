extends GutTest
## LevelUpData: volver a tirar cuesta cada vez más (base por crecimiento elevado a los usos) y la
## ruleta de los datos gira de verdad (tiempo y vueltas).

const LEVEL_UP := preload("res://data/progression/level_up.tres")


func test_reroll_cost_grows_with_each_use() -> void:
	var data := LevelUpData.new()
	data.reroll_cost = 10
	data.reroll_growth = 1.5
	assert_eq(data.reroll_cost_at(0), 10)
	assert_eq(data.reroll_cost_at(1), 15)
	assert_eq(data.reroll_cost_at(2), 23, "22,5 redondeado")


func test_the_game_data_spins_and_charges() -> void:
	assert_gt(LEVEL_UP.spin_time, 0.0)
	assert_gt(LEVEL_UP.spin_loops, 0)
	assert_gt(LEVEL_UP.reroll_cost, 0)
	assert_gt(LEVEL_UP.reroll_growth, 1.0, "repetir nunca es gratis ni igual de barato")


func test_double_chance_grows_with_luck_but_never_reaches_certain() -> void:
	var data := LevelUpData.new()
	data.double_chance = 0.5
	data.double_luck_half = 200.0
	assert_almost_eq(data.double_chance_with(0.0), 0.5, 0.0001)
	assert_almost_eq(data.double_chance_with(200.0), 0.75, 0.0001, "con su mitad, la mitad de lo que falta")
	assert_lt(data.double_chance_with(100000.0), 1.0)


func test_next_rarity_follows_the_table() -> void:
	var common: Rarity = load("res://data/rarities/common.tres")
	var rare: Rarity = load("res://data/rarities/rare.tres")
	var mythic: Rarity = load("res://data/rarities/mythic.tres")
	assert_eq(LEVEL_UP.next_rarity(common), rare)
	assert_null(LEVEL_UP.next_rarity(mythic), "la mítica no sube más")
	assert_null(LEVEL_UP.next_rarity(null))
