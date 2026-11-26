extends GutTest
## Brújula: el rumbo de una dirección en el suelo (0 = norte, −Z; π/2 = este, +X); la altura no cuenta.


func test_heading_of_each_direction() -> void:
	assert_almost_eq(Compass.heading_of(Vector3.FORWARD), 0.0, 0.001, "norte: −Z")
	assert_almost_eq(Compass.heading_of(Vector3.RIGHT), PI / 2.0, 0.001, "este: +X")
	assert_almost_eq(absf(Compass.heading_of(Vector3.BACK)), PI, 0.001, "sur: +Z")
	assert_almost_eq(Compass.heading_of(Vector3.LEFT), -PI / 2.0, 0.001, "oeste: −X")
	assert_almost_eq(Compass.heading_of(Vector3(0.0, -0.8, -1.0)), 0.0, 0.001, "mirando abajo, igual")
