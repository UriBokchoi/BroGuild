extends GutTest
## Robo de vida: cada golpe a un enemigo cura al jugador su tanto por ciento del daño hecho; sin
## robo de vida, nada.

var _data: HealthData
var _health: HealthComponent
var _lifesteal: Lifesteal


func before_each() -> void:
	_data = HealthData.new()
	_data.max_health = 100.0
	_data.lifesteal = 10.0
	var stats := StatsComponent.new()
	stats.sources.append(_data)
	add_child_autofree(stats)
	_health = HealthComponent.new()
	_health.stats = stats
	_health.rules = CombatRules.new()
	_health.rules.armor_for_half_damage = 100.0
	_health.rng = RandomNumberGenerator.new()
	add_child_autofree(_health)
	_lifesteal = Lifesteal.new()
	_lifesteal.health = _health
	_lifesteal.stats = stats
	add_child_autofree(_lifesteal)
	_health.take_damage(DamageInfo.create(50.0))


func test_hitting_an_enemy_heals_part_of_the_damage() -> void:
	var before := _health.get_current()
	EventBus.enemy_hit.emit(null, null, DamageInfo.create(200.0), 200.0)
	assert_almost_eq(_health.get_current(), before + 20.0, 0.01, "el 10 % de 200")


