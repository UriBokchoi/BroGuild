extends GutTest
## MovementData: gravedad y velocidad de salto a partir de la altura y el tiempo hasta la cima.

var _data: MovementData


func before_each() -> void:
	_data = MovementData.new()
	_data.jump_height = 2.0
	_data.jump_time_to_apex = 0.5


func test_gravity_from_height_and_time_to_apex() -> void:
	assert_almost_eq(_data.gravity(), 16.0, 1e-9, "2 × 2 m / 0,5² s")


func test_jump_velocity_from_height_and_time_to_apex() -> void:
	assert_almost_eq(_data.jump_velocity(), 8.0, 1e-9, "2 × 2 m / 0,5 s")


func test_jump_with_that_gravity_reaches_the_height() -> void:
	var velocity := _data.jump_velocity()
	var apex := velocity * velocity / (2.0 * _data.gravity())
	assert_almost_eq(apex, _data.jump_height, 1e-9)
