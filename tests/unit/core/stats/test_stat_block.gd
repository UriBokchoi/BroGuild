extends GutTest
## StatBlock: orden de cálculo, límites, redondeo, orígenes, señales y lectura de Resources.

const FixtureData := preload("res://tests/unit/core/stats/stats_test_data.gd")
const SPEED := &"speed"
const FLAT := StatModifier.Kind.FLAT
const PERCENT := StatModifier.Kind.PERCENT
const MULTIPLIER := StatModifier.Kind.MULTIPLIER

var _block: StatBlock
## Origen de los modificadores que aplican los tests.
var _source: RefCounted


func before_each() -> void:
	_block = StatBlock.new()
	_source = RefCounted.new()


func test_value_starts_at_base() -> void:
	_block.define(SPEED, 9.0)
	assert_eq(_block.get_value(SPEED), 9.0)


func test_order_is_flat_then_percent_then_multiplier() -> void:
	_block.define(SPEED, 10.0)
	_add(SPEED, MULTIPLIER, 2.0)
	_add(SPEED, PERCENT, 0.5)
	_add(SPEED, FLAT, 2.0)
	assert_eq(_block.get_value(SPEED), 36.0, "(10 + 2) × (1 + 0,5) × 2")


func test_percents_add_and_multipliers_multiply() -> void:
	_block.define(SPEED, 10.0)
	_add(SPEED, PERCENT, 0.25)
	_add(SPEED, PERCENT, 0.25)
	_add(SPEED, MULTIPLIER, 2.0)
	_add(SPEED, MULTIPLIER, 2.0)
	assert_eq(_block.get_value(SPEED), 60.0, "10 × (1 + 0,25 + 0,25) × 2 × 2")


func test_same_modifier_twice_stacks() -> void:
	_block.define(SPEED, 10.0)
	var modifier := StatModifier.create(SPEED, FLAT, 1.0)
	_block.add_modifier(modifier, _source)
	_block.add_modifier(modifier, _source)
	assert_eq(_block.get_value(SPEED), 12.0)


func test_value_is_clamped_to_limits() -> void:
	_block.define(SPEED, 5.0, 0.0, 10.0)
	assert_eq(_value_with_flat(SPEED, 100.0), 10.0)
	assert_eq(_value_with_flat(SPEED, -100.0), 0.0)


func test_integer_stats_round_to_nearest() -> void:
	_block.define(&"jumps", 3.0, 0.0, INF, true)
	_add(&"jumps", PERCENT, 0.5)
	assert_eq(_block.get_value(&"jumps"), 5.0, "3 × 1,5 = 4,5 → 5")
	assert_eq(_block.get_int(&"jumps"), 5)


func test_remove_modifiers_from_only_removes_that_source() -> void:
	_block.define(SPEED, 10.0)
	_add(SPEED, FLAT, 5.0)
	_block.add_modifier(StatModifier.create(SPEED, FLAT, 1.0), RefCounted.new())
	_block.remove_modifiers_from(_source)
	assert_eq(_block.get_value(SPEED), 11.0)


func test_lists_stats_in_definition_order_and_keeps_their_base() -> void:
	_block.define(SPEED, 10.0)
	_block.define(&"jumps", 1.0)
	_add(SPEED, PERCENT, 0.5)
	var expected: Array[StringName] = [SPEED, &"jumps"]
	assert_eq(_block.get_stats(), expected)
	assert_eq(_block.get_base(SPEED), 10.0, "la base no cambia con los modificadores")
	assert_eq(_block.get_value(SPEED), 15.0)


func test_stat_changed_reports_new_and_previous_value() -> void:
	_block.define(SPEED, 10.0)
	watch_signals(_block)
	_add(SPEED, FLAT, 2.0)
	assert_signal_emitted_with_parameters(_block, "stat_changed", [SPEED, 12.0, 10.0])


func test_stat_changed_not_emitted_if_value_stays_the_same() -> void:
	_block.define(SPEED, 10.0, 0.0, 10.0)
	watch_signals(_block)
	_add(SPEED, FLAT, 5.0)
	assert_signal_not_emitted(_block, "stat_changed", "ya estaba en el máximo")


func test_define_from_resource_reads_exported_numbers_only() -> void:
	var defined := _block.define_from_resource(FixtureData.new())
	var expected: Array[StringName] = [
		&"speed", &"jumps", &"offset", &"angle", &"free_float", &"free_int"
	]
	assert_eq(defined, expected, "sin enums, bools, curvas ni variables sin @export")
	assert_eq(_block.get_value(SPEED), 9.0, "la base es el valor del Resource")


func test_export_range_is_the_limit_unless_open() -> void:
	_block.define_from_resource(FixtureData.new())
	assert_eq(_value_with_flat(&"speed", -100.0), 0.0, "mínimo del rango")
	assert_eq(_value_with_flat(&"speed", 100.0), 109.0, "or_greater: sin máximo")
	assert_eq(_value_with_flat(&"offset", 100.0), 10.0, "máximo del rango")
	assert_eq(_value_with_flat(&"offset", -100.0), -100.0, "or_less: sin mínimo")
	assert_eq(_value_with_flat(&"jumps", 100.0), 5.0, "rango de un int")
	assert_eq(_value_with_flat(&"free_float", -100.0), -98.0, "sin rango: sin límites")


func test_radians_as_degrees_limits_are_converted() -> void:
	_block.define_from_resource(FixtureData.new())
	assert_almost_eq(_value_with_flat(&"angle", 100.0), deg_to_rad(90.0), 1e-9)


func test_int_properties_are_integer_stats() -> void:
	_block.define_from_resource(FixtureData.new())
	_add(&"free_int", PERCENT, 0.5)
	assert_eq(_block.get_value(&"free_int"), 5.0, "3 × 1,5 = 4,5 → 5")


func test_unknown_stat_is_an_error() -> void:
	assert_eq(_block.get_value(&"missing"), 0.0)
	assert_push_error("missing")


func test_modifier_for_unknown_stat_is_rejected() -> void:
	_add(&"missing", FLAT, 1.0)
	assert_push_error("missing")
	assert_false(_block.has_stat(&"missing"))


func test_stat_is_defined_only_once() -> void:
	assert_true(_block.define(SPEED, 1.0))
	assert_false(_block.define(SPEED, 2.0))
	assert_push_error("definida")
	assert_eq(_block.get_value(SPEED), 1.0)


func test_min_above_max_is_rejected() -> void:
	assert_false(_block.define(SPEED, 1.0, 5.0, 0.0))
	assert_push_error("mínimo")
	assert_false(_block.has_stat(SPEED))


func _add(stat: StringName, kind: StatModifier.Kind, amount: float) -> void:
	_block.add_modifier(StatModifier.create(stat, kind, amount), _source)


## Valor de [param stat] con un modificador plano temporal.
func _value_with_flat(stat: StringName, amount: float) -> float:
	_add(stat, FLAT, amount)
	var value := _block.get_value(stat)
	_block.remove_modifiers_from(_source)
	return value
