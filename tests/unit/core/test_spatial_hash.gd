extends GutTest
## SpatialHash: encuentra lo que hay dentro de un radio en el plano XZ, mirando solo las celdas
## cercanas, y puede excluir a quien pregunta.

var _hash: SpatialHash
var _a: RefCounted
var _b: RefCounted
var _c: RefCounted


func before_each() -> void:
	_hash = SpatialHash.new(2.0)
	_a = RefCounted.new()
	_b = RefCounted.new()
	_c = RefCounted.new()
	_hash.insert(_a, Vector3(0.0, 0.0, 0.0))
	_hash.insert(_b, Vector3(1.5, 5.0, 0.0))
	_hash.insert(_c, Vector3(10.0, 0.0, 10.0))


func test_finds_items_within_the_radius_across_cells() -> void:
	var near := _hash.items_near(Vector3(0.5, 0.0, 0.0), 1.2)
	assert_has(near, _a)
	assert_has(near, _b, "la altura no cuenta")
	assert_does_not_have(near, _c)


func test_excludes_the_one_asking() -> void:
	var positions := _hash.positions_near(Vector3.ZERO, 2.0, _a)
	assert_eq(positions, PackedVector3Array([Vector3(1.5, 5.0, 0.0)]))


func test_negative_coordinates_work() -> void:
	var item := RefCounted.new()
	_hash.insert(item, Vector3(-3.1, 0.0, -0.1))
	assert_has(_hash.items_near(Vector3(-2.9, 0.0, 0.1), 0.5), item)


func test_clear_empties_it() -> void:
	_hash.clear()
	assert_eq(_hash.size(), 0)
	assert_eq(_hash.items_near(Vector3.ZERO, 100.0).size(), 0)
