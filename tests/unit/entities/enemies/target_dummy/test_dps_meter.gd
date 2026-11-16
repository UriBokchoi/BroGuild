extends GutTest
## DpsMeter: daño por segundo desde el primer golpe; tras un rato sin golpes deja el resultado y el
## siguiente golpe empieza de cero. Los ticks se dan a mano para medir tiempos exactos.

const TICK := 1.0 / 60.0

var _health: HealthComponent
var _meter: DpsMeter


func before_each() -> void:
	var data := HealthData.new()
	data.max_health = 100.0
	var stats := StatsComponent.new()
	stats.sources.append(data)
	add_child_autofree(stats)
	var rules := CombatRules.new()
	rules.armor_for_half_damage = 100.0
	_health = HealthComponent.new()
	_health.stats = stats
	_health.rules = rules
	_health.immortal = true
	add_child_autofree(_health)
	_meter = DpsMeter.new()
	_meter.health = _health
	_meter.reset_after = 2.0
	_meter.min_window = 1.0
	add_child_autofree(_meter)
	_meter.set_physics_process(false)


func test_regular_hits_give_damage_over_time() -> void:
	# 10 de daño cada 0,5 s durante 5 s = 20 DPS.
	for _hit: int in 10:
		_health.take_damage(DamageInfo.create(10.0))
		_ticks(0.5)
	assert_almost_eq(_meter.get_dps(), 20.0, 1.0)
	assert_eq(_meter.get_total(), 100.0)


func test_closed_measure_keeps_the_result() -> void:
	for _hit: int in 10:
		_health.take_damage(DamageInfo.create(10.0))
		_ticks(0.5)
	_ticks(5.0)
	assert_almost_eq(_meter.get_dps(), 20.0, 0.5, "no baja por el rato de espera")


func test_a_new_hit_after_closing_starts_again() -> void:
	_health.take_damage(DamageInfo.create(50.0))
	_ticks(5.0)
	_health.take_damage(DamageInfo.create(5.0))
	_ticks(TICK)
	assert_eq(_meter.get_total(), 5.0)


func test_first_hit_is_divided_by_the_minimum_window() -> void:
	_health.take_damage(DamageInfo.create(30.0))
	_ticks(0.1)
	assert_almost_eq(_meter.get_dps(), 30.0, 0.01)


func test_shows_dps_and_total() -> void:
	_health.take_damage(DamageInfo.create(30.0))
	_ticks(0.1)
	assert_string_contains(_meter.text, "30")


func _ticks(seconds: float) -> void:
	for _tick: int in roundi(seconds / TICK):
		_meter._physics_process(TICK)
