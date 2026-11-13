extends GutTest
## ResourceDir: carga los Resources de un tipo que hay en una carpeta de datos.


func test_loads_the_weapons_of_the_data_folder() -> void:
	var weapons := ResourceDir.load_all("res://data/weapons", WeaponData)
	assert_gt(weapons.size(), 0)
	for weapon: Resource in weapons:
		assert_true(weapon is WeaponData)


func test_skips_resources_of_other_types() -> void:
	assert_eq(ResourceDir.load_all("res://data/player", WeaponData).size(), 0)
