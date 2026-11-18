extends GutTest
## Leaderboard: ordena por enemigos derrotados (a igualdad, victorias y luego las más largas), se
## queda con las mejores, dice el puesto de cada una y se guarda y se lee de un ConfigFile.


func test_sorts_by_kills() -> void:
	var board := Leaderboard.new(10)
	board.add(_run(50))
	board.add(_run(300))
	board.add(_run(120))
	assert_eq(_kills(board), [300, 120, 50])


func test_returns_the_place() -> void:
	var board := Leaderboard.new(10)
	board.add(_run(50))
	board.add(_run(300))
	assert_eq(board.add(_run(120)), 1, "entre las dos")
	assert_eq(board.add(_run(999)), 0, "la mejor")


func test_ties_go_to_wins_then_to_longer_runs() -> void:
	var board := Leaderboard.new(10)
	var short := _run(100, false, 60.0)
	var long := _run(100, false, 300.0)
	var won := _run(100, true, 30.0)
	board.add(short)
	board.add(long)
	board.add(won)
	assert_eq(board.get_entries(), [won, long, short])


func test_keeps_only_the_best() -> void:
	var board := Leaderboard.new(2)
	board.add(_run(10))
	board.add(_run(30))
	assert_eq(board.add(_run(5)), -1, "no entra")
	assert_eq(board.add(_run(20)), 1, "echa a la peor")
	assert_eq(_kills(board), [30, 20])


func test_survives_a_config_file() -> void:
	var board := Leaderboard.new(10)
	board.add(_run(80, true, 400.0))
	board.add(_run(20))
	var config := ConfigFile.new()
	board.write_to(config)
	var loaded := Leaderboard.new(10)
	loaded.read_from(config)
	assert_eq(_kills(loaded), [80, 20])
	assert_true(loaded.get_entries()[0].won)
	assert_eq(loaded.get_entries()[0].seconds, 400.0)


func test_reading_ignores_what_is_not_a_run_and_trims() -> void:
	var config := ConfigFile.new()
	config.set_value(Leaderboard.SECTION, Leaderboard.KEY, [{"kills": 5}, "basura", 7, {"kills": 9}, {"kills": 1}])
	var board := Leaderboard.new(2)
	board.read_from(config)
	assert_eq(_kills(board), [9, 5])


func test_reading_nothing_leaves_it_empty() -> void:
	var board := Leaderboard.new(5)
	board.add(_run(3))
	board.read_from(ConfigFile.new())
	assert_eq(board.get_entries().size(), 0)


func _run(kills: int, won: bool = false, seconds: float = 0.0) -> RunRecord:
	var record := RunRecord.new()
	record.kills = kills
	record.won = won
	record.seconds = seconds
	return record


func _kills(board: Leaderboard) -> Array[int]:
	var kills: Array[int] = []
	for record: RunRecord in board.get_entries():
		kills.append(record.kills)
	return kills
