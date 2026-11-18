extends GutTest
## Discoveries: apunta lo descubierto por tipo e id (una vez), cuenta lo de cada tipo y se guarda y
## se lee de un ConfigFile.


func test_discovers_once() -> void:
	var found := Discoveries.new()
	assert_true(found.discover(&"enemies", &"swarmer"), "nuevo")
	assert_false(found.discover(&"enemies", &"swarmer"), "ya estaba")
	assert_true(found.has(&"enemies", &"swarmer"))
	assert_false(found.has(&"items", &"swarmer"), "cada tipo por su lado")


func test_counts_each_category() -> void:
	var found := Discoveries.new()
	found.discover(&"items", &"mead")
	found.discover(&"items", &"torch")
	found.discover(&"runes", &"vigor")
	assert_eq(found.count(&"items"), 2)
	assert_eq(found.count(&"runes"), 1)
	assert_eq(found.count(&"weapons"), 0)


func test_ignores_empty_ids() -> void:
	var found := Discoveries.new()
	assert_false(found.discover(&"items", &""))
	assert_false(found.discover(&"", &"mead"))
	assert_eq(found.count(&"items"), 0)


func test_survives_a_config_file() -> void:
	var found := Discoveries.new()
	found.discover(&"items", &"mead")
	found.discover(&"enemies", &"ent_trainer")
	var config := ConfigFile.new()
	found.write_to(config)
	var loaded := Discoveries.new()
	loaded.read_from(config)
	assert_true(loaded.has(&"items", &"mead"))
	assert_true(loaded.has(&"enemies", &"ent_trainer"))
	assert_eq(loaded.count(&"items"), 1)


func test_reading_ignores_what_is_not_a_list_of_ids() -> void:
	var config := ConfigFile.new()
	config.set_value(Discoveries.SECTION, "items", 7)
	config.set_value(Discoveries.SECTION, "runes", ["vigor", 3])
	var found := Discoveries.new()
	found.discover(&"weapons", &"sword")
	found.read_from(config)
	assert_eq(found.count(&"items"), 0)
	assert_eq(found.count(&"runes"), 1)
	assert_false(found.has(&"weapons", &"sword"), "leer empieza de cero")
