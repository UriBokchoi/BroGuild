extends GutTest
## RunRecorder: apunta enemigos y élites derrotados, daño, oro ganado (no gastado), nivel y tiempo
## (el del reloj de la ronda si la hay), y deja de apuntar al morir el jugador.

const SWARMER := preload("res://data/enemies/swarmer.tres")
const ELITE := preload("res://data/enemies/elite.tres")

var _recorder: RunRecorder
var _swarm: EnemySwarm


func before_each() -> void:
	_recorder = RunRecorder.new()
	add_child_autofree(_recorder)
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)


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


func test_without_a_round_counts_its_own_time() -> void:
	await wait_physics_frames(10)
	assert_gt(_recorder.stats.seconds, 0.0)


func test_stops_when_the_player_dies() -> void:
	EventBus.player_died.emit()
	EventBus.enemy_damaged.emit(Vector3.ZERO, 12.0, DamageInfo.create(12.0))
	EventBus.player_xp_changed.emit(0.0, 10.0, 9)
	var before := _recorder.stats.seconds
	await wait_physics_frames(5)
	assert_true(_recorder.is_stopped())
	assert_eq(_recorder.stats.damage_dealt, 0.0)
	assert_eq(_recorder.stats.level, 1)
	assert_eq(_recorder.stats.seconds, before)


func _kill(enemy: Enemy) -> void:
	enemy.health.take_damage(DamageInfo.create(100000.0))
