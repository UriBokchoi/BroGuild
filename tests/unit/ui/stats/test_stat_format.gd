extends GutTest
## StatFormat: valores con su unidad y claves de traducción.


func test_float_with_suffix_drops_trailing_zeros() -> void:
	assert_eq(StatFormat.format(9.0, _property(TYPE_FLOAT, "0.0,30.0,0.1,suffix:m/s")), "9 m/s")
	assert_eq(StatFormat.format(0.125, _property(TYPE_FLOAT, "0.0,1.0,0.01,suffix:s")), "0.13 s")


func test_radians_are_shown_in_degrees() -> void:
	var property := _property(TYPE_FLOAT, "0.0,3600.0,1.0,radians_as_degrees,suffix:°/s")
	assert_eq(StatFormat.format(deg_to_rad(720.0), property), "720 °/s")


func test_integers_have_no_decimals() -> void:
	assert_eq(StatFormat.format(3.0, _property(TYPE_INT, "0,5,1")), "3")


func test_without_range_there_is_no_unit() -> void:
	var property := {"type": TYPE_FLOAT, "hint": PROPERTY_HINT_NONE, "hint_string": ""}
	assert_eq(StatFormat.format(2.5, property), "2.5")


func test_translation_keys() -> void:
	assert_eq(StatFormat.name_key(&"run_speed"), "STAT_RUN_SPEED")
	assert_eq(StatFormat.group_key("air"), "STAT_GROUP_AIR")


func _property(type: int, hint_string: String) -> Dictionary:
	return {"type": type, "hint": PROPERTY_HINT_RANGE, "hint_string": hint_string}
