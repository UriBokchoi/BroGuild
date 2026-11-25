extends GutTest
## Tiers superados: el 1 siempre está abierto, superar uno abre el siguiente (y no se pierde lo
## superado) y se guarda y se carga igual.


func test_tier_one_is_always_open() -> void:
	var progress := LevelProgress.new()
	assert_true(progress.is_unlocked(&"brosque", 1))
	assert_false(progress.is_unlocked(&"brosque", 2))


func test_clearing_a_tier_opens_the_next() -> void:
	var progress := LevelProgress.new()
	assert_true(progress.complete(&"brosque", 1))
	assert_true(progress.is_unlocked(&"brosque", 2))
	assert_false(progress.is_unlocked(&"brosque", 3))
	assert_false(progress.is_unlocked(&"dungeon", 2), "cada nivel lleva su cuenta")


func test_clearing_a_lower_tier_does_not_lose_progress() -> void:
	var progress := LevelProgress.new()
	progress.complete(&"brosque", 2)
	assert_false(progress.complete(&"brosque", 1), "no es nuevo")
	assert_eq(progress.completed(&"brosque"), 2)
	assert_true(progress.is_unlocked(&"brosque", 3))


func test_saves_and_loads_the_same() -> void:
	var progress := LevelProgress.new()
	progress.complete(&"brosque", 2)
	var config := ConfigFile.new()
	progress.write_to(config)
	var loaded := LevelProgress.new()
	loaded.read_from(config)
	assert_eq(loaded.completed(&"brosque"), 2)
	assert_eq(loaded.completed(&"dungeon"), 0)
