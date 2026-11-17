extends GutTest
## BreakableScatter con física real: coloca todos los pedidos sobre el suelo o encima de una
## plataforma, nunca dentro de un obstáculo ni sobre la tapa de un poste, separados entre sí, y con
## la misma semilla los deja en el mismo sitio.

const SKULL := preload("res://entities/breakables/skull/skull.tscn")
const COUNT := 25
## Bloque de 4 × 2 × 4 m en (6, 0, 6): se puede poner encima, no dentro.
const BLOCK_CENTER := Vector3(6.0, 1.0, 6.0)
const BLOCK_SIZE := Vector3(4.0, 2.0, 4.0)
## Poste fino (como un tronco) en (-6, 0, -6), de 3 m: ni dentro ni encima.
const POST_AT := Vector3(-6.0, 1.5, -6.0)


func before_each() -> void:
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(40.0, 1.0, 40.0))
	_add_box(BLOCK_CENTER, BLOCK_SIZE)
	_add_box(POST_AT, Vector3(0.8, 3.0, 0.8))
	await wait_physics_frames(2)


func test_places_everything_on_free_flat_ground() -> void:
	var scatter := _make_scatter(7)
	assert_eq(scatter.scatter(), COUNT)
	var spots := _spots(scatter)
	for spot: Vector3 in spots:
		var on_block := absf(spot.x - BLOCK_CENTER.x) < BLOCK_SIZE.x * 0.5 and absf(spot.z - BLOCK_CENTER.z) < BLOCK_SIZE.z * 0.5
		var expected_height := BLOCK_SIZE.y if on_block else 0.0
		assert_almost_eq(spot.y, expected_height, 0.01, "sobre el suelo o encima del bloque, no dentro")
		assert_gt(Vector2(spot.x - POST_AT.x, spot.z - POST_AT.z).length(), scatter.clearance, "lejos del poste")
	for index: int in spots.size():
		for other: int in range(index + 1, spots.size()):
			assert_gte(spots[index].distance_to(spots[other]), scatter.min_spacing - 0.01)


func test_same_seed_same_places() -> void:
	var first := _make_scatter(11)
	first.scatter()
	var second := _make_scatter(11)
	second.scatter()
	assert_eq(_spots(first), _spots(second))


func test_can_keep_away_from_the_center() -> void:
	var scatter := _make_scatter(5)
	scatter.min_center_distance = 8.0
	scatter.scatter()
	for spot: Vector3 in _spots(scatter):
		assert_gte(Vector2(spot.x, spot.z).length(), 8.0, "las llaves del jefe, lejos de donde aparece el jugador")


func _make_scatter(seed_value: int) -> BreakableScatter:
	var entry := ScatterEntry.new()
	entry.scene = SKULL
	entry.count = COUNT
	var scatter := BreakableScatter.new()
	scatter.entries = [entry] as Array[ScatterEntry]
	scatter.half_extent = Vector2(15.0, 15.0)
	scatter.scatter_on_ready = false
	scatter.rng = RandomNumberGenerator.new()
	scatter.rng.seed = seed_value
	add_child_autofree(scatter)
	return scatter


func _spots(scatter: BreakableScatter) -> Array[Vector3]:
	var spots: Array[Vector3] = []
	for child: Node in scatter.get_children():
		spots.append((child as Node3D).global_position)
	return spots


func _add_box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	body.add_child(shape)
	body.position = center
	add_child_autofree(body)
