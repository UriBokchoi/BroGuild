extends GutTest
## EnemySteering: perseguir en el plano XZ y separarse de los vecinos cercanos.


func test_seek_goes_flat_towards_the_target_at_speed() -> void:
	var velocity := EnemySteering.seek(Vector3.ZERO, Vector3(3.0, 5.0, 4.0), 10.0)
	assert_almost_eq(velocity, Vector3(6.0, 0.0, 8.0), Vector3.ONE * 1e-4)


func test_seek_stops_when_arrived() -> void:
	assert_eq(EnemySteering.seek(Vector3.ZERO, Vector3(0.1, 0.0, 0.0), 10.0), Vector3.ZERO)


func test_separation_pushes_away_stronger_when_closer() -> void:
	var near := EnemySteering.separation(Vector3.ZERO, PackedVector3Array([Vector3(0.2, 0.0, 0.0)]), 1.0, Vector3.FORWARD)
	var far := EnemySteering.separation(Vector3.ZERO, PackedVector3Array([Vector3(0.8, 0.0, 0.0)]), 1.0, Vector3.FORWARD)
	assert_lt(near.x, 0.0, "se aparta hacia −X")
	assert_gt(near.length(), far.length())


func test_separation_ignores_neighbors_out_of_radius() -> void:
	var push := EnemySteering.separation(Vector3.ZERO, PackedVector3Array([Vector3(2.0, 0.0, 0.0)]), 1.0, Vector3.FORWARD)
	assert_eq(push, Vector3.ZERO)


func test_a_neighbor_stacked_above_does_not_push() -> void:
	var push := EnemySteering.separation(Vector3.ZERO, PackedVector3Array([Vector3(0.1, 1.3, 0.0)]), 1.1, Vector3.RIGHT)
	assert_eq(push, Vector3.ZERO, "las pilas aguantan")


func test_overlapping_neighbor_pushes_towards_the_fallback() -> void:
	var push := EnemySteering.separation(Vector3.ZERO, PackedVector3Array([Vector3.ZERO]), 1.0, Vector3.RIGHT)
	assert_eq(push, Vector3.RIGHT)
