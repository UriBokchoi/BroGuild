extends GutTest
## Borde del mapa: cuatro paredes en la cara de dentro del cuadrado de juego, sin dibujarse lejos de
## los bordes y visibles al acercarse, con el brillo alrededor del objetivo.

const BoundaryScene := preload("res://levels/common/boundary/map_boundary.tscn")

var _boundary: MapBoundary
var _target: Node3D


func before_each() -> void:
	_target = Node3D.new()
	add_child_autofree(_target)
	_boundary = BoundaryScene.instantiate() as MapBoundary
	_boundary.half_extent = Vector2(20.0, 30.0)
	_boundary.target = _target
	add_child_autofree(_boundary)


func test_four_walls_on_the_edges() -> void:
	var walls := _boundary.get_walls()
	assert_eq(walls.size(), 4)
	var inset := _boundary.inset
	assert_almost_eq(walls[0].position.z, -30.0 + inset, 0.001, "norte")
	assert_almost_eq(walls[1].position.z, 30.0 - inset, 0.001, "sur")
	assert_almost_eq(walls[2].position.x, -20.0 + inset, 0.001, "oeste")
	assert_almost_eq(walls[3].position.x, 20.0 - inset, 0.001, "este")
	assert_almost_eq((walls[0].mesh as QuadMesh).size.x, 40.0, 0.001, "de lado a lado")
	assert_almost_eq((walls[2].mesh as QuadMesh).size.x, 60.0, 0.001)


func test_hidden_far_from_the_edges_and_shown_close() -> void:
	await wait_process_frames(1)
	assert_false(_boundary.get_walls()[0].visible, "en el centro no se dibuja")
	_target.position = Vector3(20.0 - _boundary.reveal_far * 0.5, 0.0, 0.0)
	await wait_process_frames(1)
	assert_true(_boundary.get_walls()[0].visible, "cerca del borde este, sí")
	var center: Vector3 = _boundary.material.get_shader_parameter(&"reveal_center")
	var expected := _target.global_position + Vector3.UP * _boundary.reveal_height
	assert_almost_eq(center, expected, Vector3.ONE * 0.001, "brilla alrededor del objetivo")
