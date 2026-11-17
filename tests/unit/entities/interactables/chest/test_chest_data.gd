extends GutTest
## ChestData: el coste sube con la dificultad y con cada cofre abierto. Lo que sale lo prueba
## [code]test_item_pool.gd[/code].


func test_cost_grows_with_difficulty_and_with_each_chest() -> void:
	var data := ChestData.new()
	data.base_cost = 20.0
	data.cost_per_difficulty = 4.0
	data.cost_growth = 1.5
	assert_eq(data.cost_at(0.0, 0), 20)
	assert_eq(data.cost_at(5.0, 0), 40, "+4 por punto de dificultad")
	assert_eq(data.cost_at(0.0, 2), 45, "×1,5 por cofre abierto")
