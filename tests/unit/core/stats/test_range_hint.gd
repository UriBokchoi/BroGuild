extends GutTest
## RangeHint: límites, unidad y grados a partir del hint de @export_range.


func test_limits_and_suffix() -> void:
	var hint := RangeHint.parse("0.0,50.0,0.1,suffix:m/s")
	assert_eq(hint.min_value, 0.0)
	assert_eq(hint.max_value, 50.0)
	assert_eq(hint.suffix, "m/s")
	assert_false(hint.radians_as_degrees)


func test_or_greater_and_or_less_open_the_limits() -> void:
	assert_eq(RangeHint.parse("0.0,50.0,0.1,or_greater").max_value, INF)
	assert_eq(RangeHint.parse("-10.0,10.0,0.1,or_less").min_value, -INF)


func test_radians_as_degrees_converts_the_limits() -> void:
	var hint := RangeHint.parse("0.0,90.0,0.1,radians_as_degrees,suffix:°/s")
	assert_true(hint.radians_as_degrees)
	assert_almost_eq(hint.max_value, deg_to_rad(90.0), 1e-9)
	assert_eq(hint.suffix, "°/s")


func test_without_range_there_are_no_limits() -> void:
	var hint := RangeHint.parse("")
	assert_eq(hint.min_value, -INF)
	assert_eq(hint.max_value, INF)
	assert_eq(hint.suffix, "")
