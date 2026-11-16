extends GutTest
## WaveData: enemigos por segundo según la curva, con picos al final de cada intervalo, y elección
## de enemigo por pesos solo entre los ya disponibles.

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


func test_rate_follows_the_curve_in_minutes() -> void:
	assert_almost_eq(_data.rate_at(0.0), 1.0, 0.01)
	assert_almost_eq(_data.rate_at(5.0 * 60.0 + 20.0), 6.33, 0.05, "a los 5 min 20 s")


func test_peaks_at_the_end_of_each_interval() -> void:
	assert_false(_data.is_peak(30.0))
	assert_true(_data.is_peak(55.0))
	assert_false(_data.is_peak(61.0), "empieza otro intervalo")
	assert_almost_eq(_data.rate_at(55.0), _data.spawn_rate.sample(55.0 / 60.0) * 3.0, 0.001)


func test_only_available_enemies_are_picked() -> void:
	for _pick: int in 50:
		assert_same(_data.pick_enemy(60.0, _rng), _early, "el tardío sale desde el minuto 5")


func test_weights_decide_how_often() -> void:
	var late := 0
	for _pick: int in 2000:
		if _data.pick_enemy(600.0, _rng) == _late:
			late += 1
	assert_between(late, 1350, 1650, "≈ 3 de cada 4")


func test_nothing_to_pick_gives_null() -> void:
	_data.enemies = []
	assert_null(_data.pick_enemy(0.0, _rng))


func _entry(enemy: EnemyData, weight: float, from_minute: float) -> WaveEnemy:
	var entry := WaveEnemy.new()
	entry.enemy = enemy
	entry.weight = weight
	entry.from_minute = from_minute
	return entry
