extends GutTest
## Las piezas altas del Brosque (árbol grande y montañita): se suben a saltos. Cada apoyo (la cara de
## arriba de cada forma de choque) queda a menos de un salto del anterior, empezando por el suelo, y
## el más alto está a la altura donde el mapa pone el cofre o la tragaperras (top_height).

const LAYOUT := preload("res://data/layouts/brosque.tres")
const MOVEMENT := preload("res://data/player/movement.tres")


func test_every_tall_piece_can_be_climbed_by_jumping() -> void:
	var tall := 0
	for piece: LayoutPiece in LAYOUT.pieces:
		if piece.top_height <= 0.0:
			continue
		tall += 1
		var label := piece.scene.resource_path.get_file()
		var steps := _step_heights(piece.scene.instantiate() as Node3D)
		assert_false(steps.is_empty(), "%s: sin apoyos" % label)
		var previous := 0.0
		for height: float in steps:
			assert_lte(height - previous, MOVEMENT.jump_height, "%s: un apoyo a %.2f m, inalcanzable" % [label, height])
			previous = height
		assert_almost_eq(steps[-1], piece.top_height, 0.05, "%s: arriba, donde va el cofre" % label)
	assert_gt(tall, 0, "hay piezas altas")


## Altura de la cara de arriba de cada forma de choque, de menor a mayor.
func _step_heights(root: Node3D) -> Array[float]:
	var heights: Array[float] = []
	for node: Node in root.find_children("*", "CollisionShape3D", true, false):
		var shape_node := node as CollisionShape3D
		var half := 0.0
		if shape_node.shape is CylinderShape3D:
			half = (shape_node.shape as CylinderShape3D).height / 2.0
		elif shape_node.shape is SphereShape3D:
			half = (shape_node.shape as SphereShape3D).radius
		elif shape_node.shape is BoxShape3D:
			half = (shape_node.shape as BoxShape3D).size.y / 2.0
		heights.append(shape_node.position.y + half)
	heights.sort()
	root.free()
	return heights
