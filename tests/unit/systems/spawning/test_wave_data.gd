extends GutTest
## WaveData (curvas según la dificultad): enemigos por segundo según la curva, con picos del reloj
## al final de cada intervalo; elección de enemigo por pesos solo entre los ya disponibles;
## multiplicadores de stats según la dificultad, y final de la ronda.

var _data: WaveData
var _early: EnemyData
var _late: EnemyData
var _rng: RandomNumberGenerator


func before_each() -> void:
	_data = WaveData.new()
	var curve := Curve.new()
	curve.min_value = 0.0
	curve.max_value = 20.0
	curve.max_domain = 20.0
	curve.add_point(Vector2(0.0, 1.0), 0.0, 1.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	curve.add_point(Vector2(10.0, 11.0), 1.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	_data.spawn_rate = curve
	_data.peak_interval = 60.0
	_data.peak_duration = 10.0
	_data.peak_multiplier = 3.0
	_early = EnemyData.new()
	_late = EnemyData.new()
	_data.enemies = [_entry(_early, 1.0, 0.0), _entry(_late, 3.0, 5.0)]
	_rng = RandomNumberGenerator.new()
	_rng.seed = 7


func test_rate_follows_the_curve_by_difficulty() -> void:
	assert_almost_eq(_data.rate_at(0.0, 0.0), 1.0, 0.01)
	assert_almost_eq(_data.rate_at(5.0 + 20.0 / 60.0, 320.0), 6.33, 0.05, "con dificultad 5,33")


func test_peaks_at_the_end_of_each_interval() -> void:
	assert_false(_data.is_peak(30.0))
	assert_true(_data.is_peak(55.0))
	assert_false(_data.is_peak(61.0), "empieza otro intervalo")
	assert_almost_eq(_data.rate_at(2.0, 55.0), _data.spawn_rate.sample(2.0) * 3.0, 0.001, "el pico va por el reloj")


func test_only_available_enemies_are_picked() -> void:
	for _pick: int in 50:
		assert_same(_data.pick_enemy(1.0, _rng), _early, "el tardío sale desde la dificultad 5")


func test_weights_decide_how_often() -> void:
	var late := 0
	for _pick: int in 2000:
		if _data.pick_enemy(10.0, _rng) == _late:
			late += 1
	assert_between(late, 1350, 1650, "≈ 3 de cada 4")


func test_nothing_to_pick_gives_null() -> void:
	_data.enemies = []
	assert_null(_data.pick_enemy(0.0, _rng))


func test_scaling_multiplies_each_stat_by_its_curve() -> void:
	_data.stat_scaling = [_scaling(&"max_health", 2.0, 6.0), _scaling(&"damage", 1.0, 3.0)]
	var modifiers := _data.scaling_at(5.0)
	assert_eq(modifiers.stat_modifiers.size(), 2)
	var health := modifiers.stat_modifiers[0]
	assert_eq(health.stat, &"max_health")
	assert_eq(health.kind, StatModifier.Kind.MULTIPLIER)
	assert_almost_eq(health.value, 4.0, 0.01, "a medio camino de 2 a 6")
	assert_almost_eq(modifiers.stat_modifiers[1].value, 2.0, 0.01)


func test_no_scaling_gives_null() -> void:
	assert_null(_data.scaling_at(5.0))


func test_overtime_after_the_round() -> void:
	assert_false(_data.is_overtime(9999.0), "sin duración, nunca")
	_data.round_minutes = 10.0
	assert_false(_data.is_overtime(599.0))
	assert_true(_data.is_overtime(600.0))


## De [param from] con dificultad 0 a [param to] con dificultad 10, en línea recta.
func _scaling(stat: StringName, from: float, to: float) -> StatScaling:
	var curve := Curve.new()
	curve.max_value = 100.0
	curve.max_domain = 10.0
	var slope := (to - from) / 10.0
	curve.add_point(Vector2(0.0, from), 0.0, slope, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	curve.add_point(Vector2(10.0, to), slope, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	var scaling := StatScaling.new()
	scaling.stat = stat
	scaling.multiplier = curve
	return scaling


func _entry(enemy: EnemyData, weight: float, from_difficulty: float) -> WaveEnemy:
	var entry := WaveEnemy.new()
	entry.enemy = enemy
	entry.weight = weight
	entry.from_difficulty = from_difficulty
	return entry
