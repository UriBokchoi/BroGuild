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
