extends GutTest
## SpeedLines: intensidad según la velocidad horizontal.


func test_hidden_below_the_start_speed() -> void:
	assert_eq(SpeedLines.intensity_for(10.0, 15.0, 28.0), 0.0)


func test_grows_between_start_and_full_speed() -> void:
	assert_almost_eq(SpeedLines.intensity_for(21.5, 15.0, 28.0), 0.5, 1e-6)


func test_full_at_and_above_the_full_speed() -> void:
	assert_eq(SpeedLines.intensity_for(28.0, 15.0, 28.0), 1.0)
	assert_eq(SpeedLines.intensity_for(60.0, 15.0, 28.0), 1.0)


func test_same_start_and_full_switches_at_once() -> void:
	assert_eq(SpeedLines.intensity_for(19.0, 20.0, 20.0), 0.0)
	assert_eq(SpeedLines.intensity_for(20.0, 20.0, 20.0), 1.0)
