extends GutTest
## RunRecorder: apunta enemigos y élites derrotados, daño, oro ganado (no gastado), nivel y tiempo
## (el del reloj de la ronda si la hay), y deja de apuntar al morir el jugador o al ganar la partida
## (apuntando la victoria y su premio por rapidez). Si se le pide, al acabar apunta la partida en la
## clasificación (una sola vez) y se queda con su puesto.

const SWARMER := preload("res://data/enemies/swarmer.tres")
const ELITE := preload("res://data/enemies/elite.tres")
const LEADERBOARD_PATH := "user://test_run_recorder_leaderboard.cfg"

var _recorder: RunRecorder
var _swarm: EnemySwarm
var _real_path: String


func before_each() -> void:
	_real_path = Save.leaderboard_path
	Save.leaderboard_path = LEADERBOARD_PATH
	Save.load_leaderboard()
	_recorder = RunRecorder.new()
	add_child_autofree(_recorder)
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)


func after_each() -> void:
	Save.leaderboard_path = _real_path
	Save.load_leaderboard()
	if FileAccess.file_exists(LEADERBOARD_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEADERBOARD_PATH))


func test_counts_kills_and_elites() -> void:
	_kill(_swarm.spawn(SWARMER, Vector3(-3.0, 0.0, 0.0)))
	var elite := _swarm.spawn(SWARMER, Vector3(3.0, 0.0, 0.0))
	elite.promote(ELITE)
	_kill(elite)
	assert_eq(_recorder.stats.kills, 2)
	assert_eq(_recorder.stats.elite_kills, 1)


func test_adds_up_damage_dealt() -> void:
	EventBus.enemy_damaged.emit(Vector3.ZERO, 12.0, DamageInfo.create(12.0))
	EventBus.enemy_damaged.emit(Vector3.ZERO, 30.0, DamageInfo.create(30.0))
	assert_eq(_recorder.stats.damage_dealt, 42.0)


func test_gold_earned_ignores_spending() -> void:
	EventBus.player_gold_changed.emit(10.0)
	EventBus.player_gold_changed.emit(4.0)
	EventBus.player_gold_changed.emit(9.0)
	assert_eq(_recorder.stats.gold_earned, 15.0, "10 ganados, 6 gastados, 5 ganados")


func test_keeps_the_level() -> void:
	EventBus.player_xp_changed.emit(3.0, 40.0, 7)
	assert_eq(_recorder.stats.level, 7)


func test_time_follows_the_round_clock() -> void:
	EventBus.run_clock_changed.emit(125.0, false)
	await wait_physics_frames(10)
	assert_eq(_recorder.stats.seconds, 125.0, "con ronda, el de su reloj")


func test_with_tiers_the_time_adds_up_stage_after_stage() -> void:
	EventBus.run_clock_changed.emit(300.0, false)
	EventBus.run_clock_changed.emit(-1.0, false)
	EventBus.stage_started.emit(&"BROSQUE_TIER_2", 1, 2)
	EventBus.run_clock_changed.emit(0.0, false)
	EventBus.run_clock_changed.emit(20.0, false)
	assert_almost_eq(_recorder.stats.seconds, 320.0, 0.1, "el tier 1 y lo que va del 2")
	assert_eq(_recorder.stats.stage_key, &"BROSQUE_TIER_2", "y hasta dónde llegó")
	EventBus.run_won.emit(&"BROSQUE_VICTORY", 25.0, 1.0)
	assert_almost_eq(_recorder.stats.seconds, 325.0, 0.1, "al ganar, también")


func test_without_a_round_counts_its_own_time() -> void:
	await wait_physics_frames(10)
	assert_gt(_recorder.stats.seconds, 0.0)


func test_stops_when_the_player_dies() -> void:
	EventBus.player_died.emit()
	# La muerte se apunta al final del fotograma (por si cuenta como victoria).
	await wait_process_frames(1)
	EventBus.enemy_damaged.emit(Vector3.ZERO, 12.0, DamageInfo.create(12.0))
	EventBus.player_xp_changed.emit(0.0, 10.0, 9)
	var before := _recorder.stats.seconds
	await wait_physics_frames(5)
	assert_true(_recorder.is_stopped())
	assert_eq(_recorder.stats.damage_dealt, 0.0)
	assert_eq(_recorder.stats.level, 1)
	assert_eq(_recorder.stats.seconds, before)


func test_elites_and_bosses_give_bro_coins() -> void:
	_recorder.bro_coin_data = preload("res://data/meta/bro_coins.tres")
	_kill(_swarm.spawn(SWARMER, Vector3(-3.0, 0.0, 0.0)))
	var elite := _swarm.spawn(SWARMER, Vector3(3.0, 0.0, 0.0))
	elite.promote(ELITE)
	_kill(elite)
	assert_eq(_recorder.stats.bro_coins, _recorder.bro_coin_data.per_elite, "solo el élite")
	EventBus.mini_boss_defeated.emit(&"TROLLEADOR_NAME")
	assert_eq(_recorder.stats.bro_coins,
		_recorder.bro_coin_data.per_elite + _recorder.bro_coin_data.per_mini_boss, "y el miniboss")
	EventBus.boss_defeated.emit(&"BROSQUE_VICTORY", 60.0, 1.0)
	var data := _recorder.bro_coin_data
	assert_eq(_recorder.stats.bro_coins, data.per_elite + data.per_mini_boss + data.per_boss, "y el jefe")


func test_without_data_there_are_no_bro_coins() -> void:
	var elite := _swarm.spawn(SWARMER, Vector3(3.0, 0.0, 0.0))
	elite.promote(ELITE)
	_kill(elite)
	EventBus.boss_defeated.emit(&"BROSQUE_VICTORY", 60.0, 1.0)
	assert_eq(_recorder.stats.bro_coins, 0)


func _kill(enemy: Enemy) -> void:
	enemy.health.take_damage(DamageInfo.create(100000.0))


func test_winning_records_the_win_and_stops() -> void:
	EventBus.run_won.emit(&"BROSQUE_VICTORY", 75.0, 1.8)
	assert_true(_recorder.stats.won)
	assert_almost_eq(_recorder.stats.boss_bonus, 1.8, 0.001)
	assert_almost_eq(_recorder.stats.seconds, 75.0, 0.001, "lo que duró de verdad")
	assert_true(_recorder.is_stopped())


func test_records_the_run_when_asked() -> void:
	_recorder.record_runs = true
	_recorder.stats.kills = 55
	EventBus.player_died.emit()
	await wait_process_frames(1)
	var entries := Save.leaderboard.get_entries()
	assert_eq(entries.size(), 1)
	assert_eq(entries[0].kills, 55)
	assert_false(entries[0].won)
	assert_eq(_recorder.place, 0)


func test_does_not_record_unless_asked() -> void:
	EventBus.player_died.emit()
	await wait_process_frames(1)
	assert_eq(Save.leaderboard.get_entries().size(), 0)
	assert_eq(_recorder.place, -1)


func test_records_a_win_once() -> void:
	_recorder.record_runs = true
	EventBus.run_won.emit(&"BROSQUE_VICTORY", 75.0, 1.8)
	EventBus.player_died.emit()
	await wait_process_frames(1)
	var entries := Save.leaderboard.get_entries()
	assert_eq(entries.size(), 1, "morir después no apunta otra")
	assert_true(entries[0].won)
