extends GutTest
## RingBounds: paredes de choque en círculo, con la cara de dentro al radio; un rayo desde el centro
## las toca ahí, en cualquier dirección.


func test_the_walls_close_a_circle_at_its_radius() -> void:
	var ring := RingBounds.new()
	ring.radius = 20.0
	ring.segments = 24
	add_child_autofree(ring)
	assert_eq(ring.get_child_count(), 24)
	await wait_physics_frames(2)
	var space := ring.get_world_3d().direct_space_state
	for degrees: float in [0.0, 37.0, 90.0, 200.0, 311.0]:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(degrees))
		var query := PhysicsRayQueryParameters3D.create(Vector3.UP, Vector3.UP + direction * 40.0)
		var hit := space.intersect_ray(query)
		assert_false(hit.is_empty(), "%d°: hay pared" % degrees)
		var at: Vector3 = hit.get("position", Vector3.ZERO)
		assert_almost_eq(Vector2(at.x, at.z).length(), 20.0, 0.6, "%d°: a su radio" % degrees)
