extends GutTest
## RuneInventory: cada nivel de una runa suma sus modificadores a las stats del jugador; bajar de
## nivel o quitarla los retira; no pasa de su nivel máximo.

const STRENGTH := preload("res://data/runes/strength.tres")
const VIGOR := preload("res://data/runes/vigor.tres")

var _stats: StatsComponent
var _runes: RuneInventory


func before_each() -> void:
	var offense := OffenseData.new()
	offense.damage = 100.0
	offense.crit_damage = 150.0
	offense.attack_speed = 100.0
	offense.projectile_speed = 100.0
	offense.area = 100.0
	offense.duration = 100.0
	offense.knockback = 100.0
	var health := HealthData.new()
	health.max_health = 100.0
	_stats = StatsComponent.new()
	_stats.sources.append(offense)
	_stats.sources.append(health)
	add_child_autofree(_stats)
	_runes = RuneInventory.new()
	_runes.stats = _stats
	add_child_autofree(_runes)


func test_adding_a_rune_applies_its_first_level() -> void:
	assert_true(_runes.add(STRENGTH))
	assert_eq(_runes.get_level(STRENGTH), 1)
	assert_almost_eq(_stats.get_value(&"damage"), 110.0, 0.001)
	assert_false(_runes.add(STRENGTH), "ya la lleva")


func test_levels_stack_and_go_back() -> void:
	_runes.add(STRENGTH)
	_runes.set_level(STRENGTH, 3)
	assert_almost_eq(_stats.get_value(&"damage"), 130.0, 0.001)
	_runes.set_level(STRENGTH, 2)
	assert_almost_eq(_stats.get_value(&"damage"), 120.0, 0.001)


func test_removing_takes_everything_back() -> void:
	_runes.add(VIGOR)
	_runes.set_level(VIGOR, 4)
	_runes.remove(VIGOR)
	assert_false(_runes.has(VIGOR))
	assert_eq(_stats.get_value(&"max_health"), 100.0)
	assert_eq(_runes.get_runes().size(), 0)


func test_never_goes_over_the_max_level() -> void:
	_runes.set_level(VIGOR, 99)
	assert_eq(_runes.get_level(VIGOR), VIGOR.max_level())
	assert_eq(_stats.get_value(&"max_health"), 100.0 + 20.0 * VIGOR.max_level())


func test_keeps_the_order_they_were_taken() -> void:
	_runes.add(VIGOR)
	_runes.add(STRENGTH)
	assert_eq(_runes.get_runes(), [VIGOR, STRENGTH] as Array[RuneData])


func test_tells_when_a_level_changes() -> void:
	watch_signals(_runes)
	_runes.add(STRENGTH)
	assert_signal_emitted_with_parameters(_runes, "rune_changed", [STRENGTH, 1])
