extends GutTest
## StatsComponent: copias resueltas con tipo y aviso de cambios.

const FixtureData := preload("res://tests/unit/core/stats/stats_test_data.gd")

var _data: FixtureData
var _stats: StatsComponent


func before_each() -> void:
	_data = FixtureData.new()
	_stats = StatsComponent.new()
	_stats.sources.append(_data)
	add_child_autofree(_stats)


func test_resolved_copy_starts_with_base_values() -> void:
	var resolved := _stats.get_resolved(FixtureData) as FixtureData
	assert_not_same(resolved, _data, "es una copia, no el Resource de datos")
	assert_eq(resolved.speed, 9.0)


func test_modifiers_update_the_copy_but_not_the_data() -> void:
	_stats.add_modifier(StatModifier.create(&"speed", StatModifier.Kind.FLAT, 2.0), self)
	var resolved := _stats.get_resolved(FixtureData) as FixtureData
	assert_eq(resolved.speed, 11.0)
	assert_eq(_stats.get_value(&"speed"), 11.0)
	assert_eq(_data.speed, 9.0, "el Resource de datos no se toca")


func test_int_stats_stay_int_in_the_copy() -> void:
	_stats.add_modifier(StatModifier.create(&"free_int", StatModifier.Kind.PERCENT, 0.5), self)
	var resolved := _stats.get_resolved(FixtureData) as FixtureData
	assert_eq(resolved.free_int, 5)


func test_removing_the_source_restores_the_copy() -> void:
	_stats.add_modifier(StatModifier.create(&"speed", StatModifier.Kind.FLAT, 2.0), self)
	_stats.remove_modifiers_from(self)
	var resolved := _stats.get_resolved(FixtureData) as FixtureData
	assert_eq(resolved.speed, 9.0)


func test_stat_changed_arrives_after_the_copy_is_updated() -> void:
	var resolved := _stats.get_resolved(FixtureData) as FixtureData
	var seen: Array[float] = []
	_stats.stat_changed.connect(
		func(_stat: StringName, _value: float, _previous: float) -> void:
			seen.append(resolved.speed)
	)
	_stats.add_modifier(StatModifier.create(&"speed", StatModifier.Kind.FLAT, 2.0), self)
	var expected: Array[float] = [11.0]
	assert_eq(seen, expected)


func test_missing_data_type_is_an_error() -> void:
	assert_null(_stats.get_resolved(StatModifier))
	assert_push_error("no hay datos")
