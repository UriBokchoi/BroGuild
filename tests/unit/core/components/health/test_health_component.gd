extends GutTest
## HealthComponent: recibe golpes con defensa y esquiva, muere una sola vez, regenera, sube con la
## vida máxima y, si tiene invulnerabilidad, no recibe daño un momento tras cada golpe.

const TICK := 1.0 / 60.0

var _data: HealthData
var _stats: StatsComponent
var _health: HealthComponent


func before_each() -> void:
	_data = HealthData.new()
	_data.max_health = 100.0
	_stats = StatsComponent.new()
	_stats.sources.append(_data)
	add_child_autofree(_stats)
	var rules := CombatRules.new()
	rules.armor_for_half_damage = 100.0
	_health = HealthComponent.new()
	_health.stats = _stats
	_health.rules = rules
	_health.rng = RandomNumberGenerator.new()
	_health.rng.seed = 42
	add_child_autofree(_health)


func test_starts_full() -> void:
	assert_eq(_health.get_current(), 100.0)
	assert_eq(_health.get_maximum(), 100.0)


func test_damage_lowers_health_and_notifies() -> void:
	watch_signals(_health)
	assert_eq(_health.take_damage(DamageInfo.create(30.0)), 30.0)
	assert_eq(_health.get_current(), 70.0)
	assert_signal_emitted_with_parameters(_health, "health_changed", [70.0, 100.0])


func test_armor_reduces_damage() -> void:
	_stats.add_modifier(StatModifier.create(&"armor", StatModifier.Kind.FLAT, 100.0), self)
	assert_eq(_health.take_damage(DamageInfo.create(30.0)), 15.0, "100 de defensa = mitad")


func test_full_evasion_avoids_the_hit() -> void:
	_stats.add_modifier(StatModifier.create(&"evasion", StatModifier.Kind.FLAT, 90.0), self)
	watch_signals(_health)
	var evaded := 0
	for _hit: int in 200:
		if _health.take_damage(DamageInfo.create(0.1)) == 0.0:
			evaded += 1
	assert_between(evaded, 160, 200, "≈ 90 % esquivados")
	assert_signal_emitted(_health, "evaded")


func test_dies_once_at_zero() -> void:
	watch_signals(_health)
	_health.take_damage(DamageInfo.create(150.0))
	assert_eq(_health.get_current(), 0.0, "no baja de 0")
	assert_true(_health.is_dead())
	assert_eq(_health.take_damage(DamageInfo.create(10.0)), 0.0, "muerto no recibe más")
	assert_signal_emit_count(_health, "died", 1)


func test_regenerates_up_to_the_max() -> void:
	_stats.add_modifier(StatModifier.create(&"health_regen", StatModifier.Kind.FLAT, 6.0), self)
	_health.take_damage(DamageInfo.create(10.0))
	for _tick: int in 60:
		_health._physics_process(TICK)
	assert_almost_eq(_health.get_current(), 96.0, 1e-3, "6 vida en 1 s")
	for _tick: int in 120:
		_health._physics_process(TICK)
	assert_eq(_health.get_current(), 100.0, "no pasa del máximo")


func test_overkill_reports_the_whole_hit_but_removes_what_was_left() -> void:
	_health.take_damage(DamageInfo.create(80.0))
	watch_signals(_health)
	assert_eq(_health.take_damage(DamageInfo.create(50.0)), 20.0, "quita lo que quedaba")
	var amount: float = get_signal_parameters(_health, "damaged")[0]
	assert_eq(amount, 50.0, "el golpe valía 50")


func test_immortal_counts_hits_without_losing_health() -> void:
	_health.immortal = true
	watch_signals(_health)
	assert_eq(_health.take_damage(DamageInfo.create(500.0)), 0.0)
	assert_eq(_health.get_current(), 100.0)
	assert_false(_health.is_dead())
	assert_signal_emitted(_health, "damaged")
	assert_signal_not_emitted(_health, "died")


func test_reset_brings_it_back_full() -> void:
	_health.take_damage(DamageInfo.create(500.0))
	_health.reset()
	assert_false(_health.is_dead())
	assert_eq(_health.get_current(), 100.0)
	assert_eq(_health.take_damage(DamageInfo.create(10.0)), 10.0, "vuelve a recibir daño")


func test_raising_max_health_heals_the_difference() -> void:
	_health.take_damage(DamageInfo.create(50.0))
	_stats.add_modifier(StatModifier.create(&"max_health", StatModifier.Kind.FLAT, 20.0), self)
	assert_eq(_health.get_maximum(), 120.0)
	assert_eq(_health.get_current(), 70.0, "50 + los 20 nuevos")


func test_after_a_hit_it_ignores_hits_for_a_moment() -> void:
	var data := HealthData.new()
	data.max_health = 100.0
	data.invulnerability_time = 0.1
	var stats := StatsComponent.new()
	stats.sources.append(data)
	add_child_autofree(stats)
	var health := HealthComponent.new()
	health.stats = stats
	health.rules = CombatRules.new()
	health.rules.armor_for_half_damage = 100.0
	add_child_autofree(health)
	watch_signals(health)
	assert_eq(health.take_damage(DamageInfo.create(10.0)), 10.0)
	assert_signal_emitted_with_parameters(health, "invulnerability_started", [0.1])
	assert_true(health.is_invulnerable())
	assert_eq(health.take_damage(DamageInfo.create(10.0)), 0.0, "aún invulnerable")
	assert_eq(health.get_current(), 90.0)
	await wait_physics_frames(12)
	assert_false(health.is_invulnerable())
	assert_eq(health.take_damage(DamageInfo.create(10.0)), 10.0, "pasado el momento, sí")
