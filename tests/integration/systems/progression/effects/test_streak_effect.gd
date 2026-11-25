extends GutTest
## La racha (power-up): al cogerla empieza en ×1; derrotar enemigos la sube de nivel (oro y
## experiencia multiplicados, más Suerte); un golpe la baja un nivel; coger otra alarga el tiempo sin
## perder el nivel; al acabarse, todo vuelve a la normalidad. El HUD enseña «Racha ×N».

const DATA := preload("res://data/progression/streak.tres")
const SWARMER := preload("res://data/enemies/swarmer.tres")

var _effect: StreakEffect
var _stats: StatsComponent
var _health: HealthComponent
var _swarm: EnemySwarm


func before_each() -> void:
	var progression := ProgressionData.new()
	progression.currency_gain = 100.0
	progression.xp_gain = 100.0
	var health_data := HealthData.new()
	health_data.max_health = 1000.0
	_stats = StatsComponent.new()
	_stats.sources.append(progression)
	_stats.sources.append(health_data)
	add_child_autofree(_stats)
	_health = HealthComponent.new()
	_health.stats = _stats
	_health.rules = preload("res://data/combat/rules.tres")
	add_child_autofree(_health)
	_effect = StreakEffect.new()
	_effect.reward = &"streak"
	_effect.data = DATA
	_effect.stats = _stats
	_effect.health = _health
	add_child_autofree(_effect)
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)


func test_kills_raise_the_multiplier() -> void:
	EventBus.pickup_collected.emit(&"streak", 30.0)
	assert_true(_effect.is_active())
	assert_eq(_effect.get_multiplier(), 1.0, "empieza en ×1")
	_kill(DATA.kills[1])
	assert_eq(_effect.get_multiplier(), DATA.multipliers[1])
	assert_almost_eq(_stats.get_value(&"currency_gain"), 100.0 * DATA.multipliers[1], 0.01, "más oro")
	assert_almost_eq(_stats.get_value(&"xp_gain"), 100.0 * DATA.multipliers[1], 0.01, "más experiencia")
	assert_gt(_stats.get_value(&"luck"), 0.0, "y Suerte")


func test_a_hit_drops_a_level() -> void:
	EventBus.pickup_collected.emit(&"streak", 30.0)
	_kill(DATA.kills[2])
	assert_eq(_effect.get_multiplier(), DATA.multipliers[2])
	_health.take_damage(DamageInfo.create(5.0))
	assert_eq(_effect.get_multiplier(), DATA.multipliers[1], "un golpe, un nivel menos")


func test_it_runs_out() -> void:
	EventBus.pickup_collected.emit(&"streak", 0.3)
	_kill(DATA.kills[1])
	await wait_seconds(0.4)
	assert_false(_effect.is_active())
	assert_almost_eq(_stats.get_value(&"currency_gain"), 100.0, 0.01, "todo vuelve a la normalidad")


func test_another_one_extends_it_without_losing_the_level() -> void:
	EventBus.pickup_collected.emit(&"streak", 5.0)
	_kill(DATA.kills[1])
	EventBus.pickup_collected.emit(&"streak", 30.0)
	assert_eq(_effect.get_multiplier(), DATA.multipliers[1])
	assert_almost_eq(_effect.get_time_left(), 30.0, 0.1)


func test_the_hud_shows_it() -> void:
	var meter := StreakMeter.new()
	add_child_autofree(meter)
	EventBus.pickup_collected.emit(&"streak", 30.0)
	await wait_process_frames(1)
	assert_true(meter.visible)
	assert_string_contains(meter.text, "1")
	EventBus.streak_changed.emit(0.0, 0.0)
	assert_false(meter.visible)


## Derrota a [param count] enemigos.
func _kill(count: int) -> void:
	for index: int in count:
		var enemy := _swarm.spawn(SWARMER, Vector3(float(index % 10) * 2.0, 0.0, floorf(index / 10.0) * 2.0 + 5.0))
		enemy.health.take_damage(DamageInfo.create(1.0e6))
