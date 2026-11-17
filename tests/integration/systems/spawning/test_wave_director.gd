extends GutTest
## WaveDirector con física real: en marcha saca enemigos en el suelo a la distancia de sus datos,
## sin pasar del máximo y con la probabilidad de élite de sus datos; parado no saca ninguno y puede
## retirar a los que hay. La dificultad (stat del jugador) sube 1 por minuto en marcha y, con más
## dificultad, los enemigos salen más fuertes.

const SWARMER := preload("res://data/enemies/swarmer.tres")
const ELITE := preload("res://data/enemies/elite.tres")

var _target: Node3D
var _swarm: EnemySwarm
var _director: WaveDirector


func before_each() -> void:
	_add_ground()
	_target = Node3D.new()
	add_child_autofree(_target)
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)
	_director = WaveDirector.new()
	_director.data = _wave_data(60.0, 5)
	_director.swarm = _swarm
	_director.target = _target
	_director.rng = RandomNumberGenerator.new()
	_director.rng.seed = 3
	add_child_autofree(_director)


func test_does_nothing_until_started() -> void:
	await wait_physics_frames(10)
	assert_eq(_swarm.active_count(), 0)


func test_spawns_on_the_ground_at_the_data_distance() -> void:
	_director.start()
	await wait_physics_frames(3)
	assert_gt(_swarm.active_count(), 0)
	for enemy: Enemy in _swarm.get_active():
		var flat := Vector2(enemy.global_position.x, enemy.global_position.z).length()
		assert_between(flat, 9.9, 15.1, "entre la distancia mínima y la máxima")


func test_never_goes_over_the_max_alive() -> void:
	_director.start()
	await wait_physics_frames(30)
	assert_eq(_swarm.active_count(), 5)


func test_stop_clears_the_enemies() -> void:
	_director.start()
	await wait_physics_frames(5)
	_director.stop()
	assert_false(_director.is_running())
	assert_eq(_swarm.active_count(), 0)
	await wait_physics_frames(5)
	assert_eq(_swarm.active_count(), 0, "parado no saca más")


func test_elites_follow_the_data_chance() -> void:
	_director.data.elite = ELITE
	_director.data.elite_chance = _flat_curve(100.0)
	_director.start()
	await wait_physics_frames(3)
	assert_gt(_swarm.active_count(), 0)
	for enemy: Enemy in _swarm.get_active():
		assert_true(enemy.is_elite(), "100 %: todos élites")


func test_no_elite_chance_no_elites() -> void:
	_director.data.elite = ELITE
	_director.start()
	await wait_physics_frames(3)
	for enemy: Enemy in _swarm.get_active():
		assert_false(enemy.is_elite(), "sin curva, ninguno")


func test_enemies_come_with_the_stats_of_their_difficulty() -> void:
	var scaling := StatScaling.new()
	scaling.stat = &"max_health"
	scaling.multiplier = _flat_curve(3.0)
	_director.data.stat_scaling = [scaling]
	var normal := SWARMER.stat_sources[0] as HealthData
	_director.start()
	await wait_physics_frames(3)
	assert_gt(_swarm.active_count(), 0)
	for enemy: Enemy in _swarm.get_active():
		assert_almost_eq(enemy.health.get_maximum(), normal.max_health * 3.0, 0.01)
		assert_eq(enemy.health.get_current(), enemy.health.get_maximum())


func test_announces_the_clock_every_second() -> void:
	_director.data.round_minutes = 1.0 / 60.0
	watch_signals(EventBus)
	_director.start()
	assert_signal_emitted_with_parameters(EventBus, "run_clock_changed", [0.0, false])
	await wait_seconds(1.1)
	var seconds: float = get_signal_parameters(EventBus, "run_clock_changed")[0]
	var overtime: bool = get_signal_parameters(EventBus, "run_clock_changed")[1]
	assert_gte(seconds, 1.0)
	assert_true(overtime, "pasado su minuto de ronda")
	_director.stop()
	assert_signal_emitted_with_parameters(EventBus, "run_clock_changed", [-1.0, false])


func test_difficulty_rises_one_per_minute_on_the_stats() -> void:
	var stats := _difficulty_stats()
	_director.difficulty_stats = stats
	_director.start()
	assert_eq(_director.get_difficulty(), 0.0)
	await wait_seconds(1.1)
	assert_almost_eq(stats.get_value(&"difficulty"), 1.0 / 60.0, 0.001, "un segundo, 1/60")
	_director.stop()
	assert_eq(stats.get_value(&"difficulty"), 0.0, "parado, sin la parte del tiempo")


func test_extra_difficulty_brings_stronger_enemies() -> void:
	var stats := _difficulty_stats()
	stats.add_modifier(StatModifier.create(&"difficulty", StatModifier.Kind.FLAT, 10.0), self)
	_director.difficulty_stats = stats
	var scaling := StatScaling.new()
	scaling.stat = &"max_health"
	scaling.multiplier = _line(1.0, 3.0, 10.0)
	_director.data.stat_scaling = [scaling]
	var normal := SWARMER.stat_sources[0] as HealthData
	_director.start()
	await wait_physics_frames(3)
	assert_gt(_swarm.active_count(), 0)
	for enemy: Enemy in _swarm.get_active():
		assert_almost_eq(enemy.health.get_maximum(), normal.max_health * 3.0, 0.1, "como con dificultad 10")


func test_without_ground_nobody_spawns() -> void:
	_target.position = Vector3(500.0, 0.0, 500.0)
	_director.start()
	await wait_physics_frames(10)
	assert_eq(_swarm.active_count(), 0)


func test_enemies_only_spawn_inside_the_play_area() -> void:
	# Solo la mitad x > 0 alrededor del objetivo: ninguno sale en la otra.
	_director.play_area = Rect2(0.0, -40.0, 40.0, 80.0)
	_director.start()
	await wait_physics_frames(6)
	assert_gt(_swarm.active_count(), 0)
	for enemy: Enemy in _swarm.get_active():
		assert_gte(enemy.global_position.x, 0.0)


func _wave_data(rate: float, max_alive: int) -> WaveData:
	var data := WaveData.new()
	var curve := Curve.new()
	curve.max_value = 100.0
	curve.add_point(Vector2(0.0, rate))
	curve.add_point(Vector2(1.0, rate))
	data.spawn_rate = curve
	data.max_alive = max_alive
	data.min_spawn_distance = 10.0
	data.max_spawn_distance = 15.0
	var entry := WaveEnemy.new()
	entry.enemy = SWARMER
	entry.weight = 1.0
	data.enemies = [entry]
	return data


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)


func _difficulty_stats() -> StatsComponent:
	var stats := StatsComponent.new()
	stats.sources.append(ProgressionData.new())
	add_child_autofree(stats)
	return stats


## De [param from] con dificultad 0 a [param to] con [param domain], en línea recta.
func _line(from: float, to: float, domain: float) -> Curve:
	var curve := Curve.new()
	curve.max_value = 100.0
	curve.max_domain = domain
	var slope := (to - from) / domain
	curve.add_point(Vector2(0.0, from), 0.0, slope, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	curve.add_point(Vector2(domain, to), slope, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	return curve


func _flat_curve(value: float) -> Curve:
	var curve := Curve.new()
	curve.max_value = 100.0
	curve.add_point(Vector2(0.0, value))
	curve.add_point(Vector2(1.0, value))
	return curve
