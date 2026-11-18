extends GutTest
## HealShopData: el coste sube con la dificultad y con cada uso.


func test_cost_grows_with_difficulty_and_with_each_use() -> void:
	var data := HealShopData.new()
	data.base_cost = 10.0
	data.cost_per_difficulty = 2.0
	data.cost_growth = 1.5
	assert_eq(data.cost_at(0.0, 0), 10)
	assert_eq(data.cost_at(5.0, 0), 20, "+2 por punto de dificultad")
	assert_eq(data.cost_at(0.0, 2), 23, "×1,5 por uso: 22,5 → 23")
