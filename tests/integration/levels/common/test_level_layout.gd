extends GutTest
## Mapa generado (con los datos del Brosque): las piezas no se pisan, quedan dentro del cuadrado y
## las mesetas fuera del claro; las tragaperras de arriba van encima de una meseta; ningún árbol
## suelto pisa una pieza; el altar del jefe queda al borde del claro mirándolo; con la misma semilla
## sale el mismo mapa y con otra, otro.

const DATA := preload("res://data/layouts/brosque.tres")


func test_pieces_do_not_overlap_and_stay_inside() -> void:
	var layout := _make_layout(5)
	var zones := layout.get_occupied()
	for index: int in zones.size():
		var zone := zones[index]
		assert_lte(maxf(absf(zone.x), absf(zone.y)) + zone.z, DATA.half_size + 0.01, "dentro del cuadrado")
		for other: int in range(index + 1, zones.size()):
			var distance := Vector2(zone.x, zone.y).distance_to(Vector2(zones[other].x, zones[other].y))
			assert_gte(distance, zone.z + zones[other].z, "sin pisarse")


func test_plateaus_avoid_the_clearing_and_carry_the_top_slot_machines() -> void:
	var layout := _make_layout(8)
	var tops: Array[Vector3] = []
	for piece: Node3D in layout.get_pieces():
		if piece is SlotMachine and piece.position.y > 0.0:
			tops.append(piece.position)
		elif piece.scene_file_path.contains("plateau"):
			assert_gt(Vector2(piece.position.x, piece.position.z).length(), DATA.clearing_radius)
	assert_eq(tops.size(), DATA.top_pieces[0].count, "una en cada meseta elegida")


func test_the_altar_stands_at_the_edge_of_the_clearing_facing_it() -> void:
	var layout := _make_layout(6)
	var altars := layout.get_pieces().filter(func(piece: Node3D) -> bool: return piece is BossAltar)
	assert_eq(altars.size(), 1)
	var altar := altars[0] as Node3D
	var ring := Vector2.ZERO
	for piece: LayoutPiece in DATA.pieces:
		if piece.face_center:
			ring = piece.ring
	assert_between(Vector2(altar.position.x, altar.position.z).length(), ring.x, ring.y, "al borde del claro")
	var to_center := -Vector3(altar.position.x, 0.0, altar.position.z).normalized()
	assert_gt((-altar.basis.z).dot(to_center), 0.99, "mira al claro")


func test_trees_never_stand_on_a_piece() -> void:
	var layout := _make_layout(3)
	var zones := layout.get_occupied()
	var colliders := layout.get_node(^"Forest/TreeColliders").get_children()
	for collider: Node in colliders:
		var at := (collider as Node3D).position
		for zone: Vector3 in zones:
			assert_gte(Vector2(at.x, at.z).distance_to(Vector2(zone.x, zone.y)), zone.z, "ningún tronco encima de una pieza")


func test_same_seed_same_map_other_seed_other_map() -> void:
	assert_eq(_make_layout(21).get_occupied(), _make_layout(21).get_occupied())
	assert_ne(_make_layout(21).get_occupied(), _make_layout(22).get_occupied())


func _make_layout(seed_value: int) -> LevelLayout:
	var layout := LevelLayout.new()
	layout.data = DATA
	layout.rng = RandomNumberGenerator.new()
	layout.rng.seed = seed_value
	add_child_autofree(layout)
	return layout
