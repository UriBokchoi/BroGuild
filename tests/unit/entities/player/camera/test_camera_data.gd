extends GutTest
## CameraData: distancia según el nivel.

var _data: CameraData


func before_each() -> void:
	_data = CameraData.new()
	_data.base_distance = 5.0
	_data.distance_by_level = _linear_curve(Vector2(1.0, 1.0), Vector2(100.0, 1.4))


func test_level_one_uses_the_start_of_the_curve() -> void:
	assert_almost_eq(_data.distance_at(1), 5.0, 1e-6)


func test_last_level_of_the_curve() -> void:
	assert_almost_eq(_data.distance_at(100), 7.0, 1e-5)


func test_levels_past_the_curve_keep_its_last_value() -> void:
	assert_almost_eq(_data.distance_at(150), _data.distance_at(100), 1e-9)


func test_without_curve_uses_base_distance() -> void:
	_data.distance_by_level = null
	assert_eq(_data.distance_at(50), 5.0)


func test_fov_opens_with_speed_following_its_curve() -> void:
	_data.fov = 75.0
	_data.fov_by_speed = _linear_curve(Vector2(10.0, 0.0), Vector2(30.0, 20.0))
	assert_almost_eq(_data.fov_at(10.0), 75.0, 1e-6)
	assert_almost_eq(_data.fov_at(20.0), 85.0, 1e-4)
	assert_almost_eq(_data.fov_at(30.0), 95.0, 1e-4)


func test_without_fov_curve_the_fov_does_not_change() -> void:
	_data.fov = 75.0
	assert_eq(_data.fov_at(40.0), 75.0)


## Curva lineal entre dos puntos (x: nivel, y: multiplicador).
static func _linear_curve(from: Vector2, to: Vector2) -> Curve:
	var curve := Curve.new()
	# Dominio y rango antes de los puntos: Curve recorta los puntos a ellos.
	curve.max_domain = to.x
	curve.min_domain = from.x
	curve.max_value = maxf(from.y, to.y)
	curve.add_point(from, 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	curve.add_point(to, 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	return curve
