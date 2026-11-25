extends GutTest
## RunRecord: toma lo apuntado en la partida, el personaje y el nivel, y se guarda y se lee como
## diccionario (lo que falte, con su valor de serie).

const WARRIOR := preload("res://data/characters/warrior.tres")
const BROSQUE := preload("res://data/levels/brosque.tres")


func test_takes_the_run_the_character_and_the_level() -> void:
	var stats := RunStats.new()
	stats.kills = 321
	stats.elite_kills = 3
	stats.seconds = 410.0
	stats.level = 14
	stats.won = true
	var record := RunRecord.create(stats, WARRIOR, BROSQUE)
	assert_eq(record.character_id, &"warrior")
	assert_eq(record.character_name_key, WARRIOR.name_key)
	assert_eq(record.level_name_key, BROSQUE.name_key)
	assert_eq(record.kills, 321)
	assert_eq(record.elite_kills, 3)
	assert_eq(record.seconds, 410.0)
	assert_eq(record.player_level, 14)
	assert_true(record.won)
	assert_gt(record.finished_at, 0.0, "con la fecha de ahora")


func test_keeps_the_tier_of_a_level_with_tiers() -> void:
	var record := RunRecord.create(RunStats.new(), WARRIOR, BROSQUE, 2)
	assert_eq(record.tier, 2)
	assert_eq(RunRecord.from_dict(record.to_dict()).tier, 2)
	assert_eq(RunRecord.create(RunStats.new(), WARRIOR, null, 2).tier, 0, "sin nivel, sin tier")


func test_without_character_or_level_they_stay_empty() -> void:
	var record := RunRecord.create(RunStats.new(), null, null)
	assert_eq(record.character_name_key, &"")
	assert_eq(record.level_name_key, &"")


func test_round_trips_through_a_dictionary() -> void:
	var stats := RunStats.new()
	stats.kills = 77
	stats.seconds = 95.5
	stats.level = 6
	var record := RunRecord.create(stats, WARRIOR, BROSQUE)
	var copy := RunRecord.from_dict(record.to_dict())
	assert_eq(copy.to_dict(), record.to_dict())


func test_missing_fields_get_their_defaults() -> void:
	var record := RunRecord.from_dict({"kills": 12})
	assert_eq(record.kills, 12)
	assert_eq(record.player_level, 1)
	assert_false(record.won)
	assert_eq(record.character_name_key, &"")
