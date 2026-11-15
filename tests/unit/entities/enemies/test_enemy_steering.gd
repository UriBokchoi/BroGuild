extends GutTest
## EnemySteering: perseguir en el plano XZ (con un desvío que desaparece al llegar), separarse de
## los vecinos cercanos y saber cuándo trepar sobre uno que tapa el paso.


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


func test_approach_deviates_far_away_and_goes_straight_near() -> void:
	var target := Vector3(0.0, 0.0, -20.0)
	var far := EnemySteering.approach(Vector3.ZERO, target, 1.0, deg_to_rad(30.0))
	assert_almost_eq(rad_to_deg(far.angle_to(Vector3.FORWARD)), 30.0, 0.1, "lejos, con su desvío")
	var near := EnemySteering.approach(Vector3(0.0, 0.0, -19.5), target, 1.0, deg_to_rad(30.0))
	assert_lt(rad_to_deg(near.angle_to(Vector3.FORWARD)), 5.0, "cerca, casi derecho")


func test_climbs_over_a_foothold_ahead_that_is_closer_to_the_target() -> void:
	var target := Vector3(0.0, 0.0, -10.0)
	var ahead := PackedVector3Array([Vector3(0.0, 0.0, -0.8)])
	assert_true(EnemySteering.blocked_ahead(Vector3.ZERO, Vector3.FORWARD, target, ahead, 1.1))


func test_never_climbs_over_one_further_from_the_target() -> void:
	var target := Vector3(10.0, 0.0, 0.0)
	# A un lado y más lejos del objetivo: si treparan los dos a la vez, no pararían.
	var beside := PackedVector3Array([Vector3(-0.3, 0.0, -0.75)])
	assert_false(EnemySteering.blocked_ahead(Vector3.ZERO, Vector3.FORWARD, target, beside, 1.1))


func test_a_foothold_already_below_is_not_in_the_way() -> void:
	var target := Vector3(0.0, 0.0, -10.0)
	var below := PackedVector3Array([Vector3(0.0, -1.3, -0.3)])
	assert_false(EnemySteering.blocked_ahead(Vector3.ZERO, Vector3.FORWARD, target, below, 1.1))
