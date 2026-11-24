class_name ForestBuilder
extends RefCounted
## Construye el bosque de un mapa generado ([LevelLayout], [ForestData]): árboles sueltos que
## esquivan el claro y las piezas, un anillo denso junto a las paredes (con colisión) y una banda
## grande fuera de ellas (sin colisión). Los dibuja por trozos de [member ForestData.chunk_size]
## metros, cada uno con cinco MultiMesh (tronco y copas: pocas llamadas de dibujo para cientos de
## árboles, y los trozos que no se ven no se dibujan), y les da un solo cuerpo con un cilindro por
## tronco.

## Modelo del árbol (como el de una escena): tronco, tres conos de pino y la copa redonda; cada
## parte, su radio arriba, su radio abajo, su alto y la altura de su centro.
const TRUNK_SHAPE := Vector4(0.22, 0.36, 3.0, 1.5)
const PINE_PARTS: Array[Vector4] = [Vector4(0.0, 1.7, 2.4, 3.4), Vector4(0.0, 1.25, 2.0, 4.6), Vector4(0.0, 0.8, 1.6, 5.7)]
const CROWN_SHAPE := Vector4(1.8, 3.2, 0.0, 4.2)
const RADIAL_SEGMENTS := 8


## Construye el bosque bajo [param parent]. [param occupied] son las piezas (x, z, radio).
static func build(
	parent: Node3D,
	forest: ForestData,
	half_size: float,
	clearing: float,
	occupied: Array[Vector3],
	rng: RandomNumberGenerator,
) -> void:
	var trees := _scatter(forest, half_size, clearing, occupied, rng)
	trees.append_array(_border(forest, occupied, rng))
	trees.append_array(_outer_band(forest, occupied, rng))
	var root := Node3D.new()
	root.name = "Forest"
	parent.add_child(root)
	_add_parts(root, forest, trees)
	_add_colliders(root, forest, trees)


## Árboles sueltos: al azar, sin pisar el claro ni las piezas y separados entre sí.
static func _scatter(forest: ForestData, half: float, clearing: float, occupied: Array[Vector3], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var trees: Array[Dictionary] = []
	for _attempt: int in forest.attempts:
		if trees.size() >= forest.max_trees:
			break
		var at := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		if at.length() < clearing or _blocked(at, occupied, forest.piece_margin) or _crowded(at, trees, forest.spacing):
			continue
		trees.append(_tree(forest, at, forest.scale_range, true, rng))
	return trees


## Anillo denso junto a las paredes, en los cuatro lados (sin pisar lo reservado, como una taberna).
static func _border(forest: ForestData, occupied: Array[Vector3], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var trees: Array[Dictionary] = []
	var steps := floori(forest.border * 2.0 / forest.border_step)
	for side: int in 4:
		for step: int in steps + 1:
			var along := -forest.border + step * forest.border_step + rng.randf_range(-1.0, 1.0)
			var depth := forest.border + rng.randf_range(0.0, forest.border_depth)
			var at := Vector2(along, depth) if side < 2 else Vector2(depth, along)
			if side % 2 == 1:
				at = -at
			if not _blocked(at, occupied, forest.piece_margin):
				trees.append(_tree(forest, at, forest.scale_range, true, rng))
	return trees


## Banda de fuera: rejilla con temblor, solo más allá de [member ForestData.outer_start] (sin pisar lo
## reservado).
static func _outer_band(forest: ForestData, occupied: Array[Vector3], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var trees: Array[Dictionary] = []
	var steps := floori(forest.outer_end * 2.0 / forest.outer_step)
	var jitter := forest.outer_step * 0.4
	for row: int in steps + 1:
		for column: int in steps + 1:
			var spot := Vector2(-forest.outer_end + column * forest.outer_step, -forest.outer_end + row * forest.outer_step)
			if maxf(absf(spot.x), absf(spot.y)) < forest.outer_start:
				continue
			spot += Vector2(rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter))
			if not _blocked(spot, occupied, forest.piece_margin):
				trees.append(_tree(forest, spot, forest.outer_scale_range, false, rng))
	return trees


static func _tree(forest: ForestData, at: Vector2, scale_range: Vector2, collides: bool, rng: RandomNumberGenerator) -> Dictionary:
	var round_tree := rng.randf() < forest.round_share
	var palette := forest.round_colors if round_tree else forest.pine_colors
	if rng.randf() < forest.accent_share and not forest.accent_colors.is_empty():
		palette = forest.accent_colors
	return {
		"at": at,
		"scale": rng.randf_range(scale_range.x, scale_range.y),
		"yaw": rng.randf_range(0.0, TAU),
		"round": round_tree,
		"color": palette[rng.randi_range(0, palette.size() - 1)],
		"collides": collides,
	}


static func _blocked(at: Vector2, occupied: Array[Vector3], margin: float) -> bool:
	for zone: Vector3 in occupied:
		if at.distance_to(Vector2(zone.x, zone.y)) < zone.z + margin:
			return true
	return false


static func _crowded(at: Vector2, trees: Array[Dictionary], spacing: float) -> bool:
	for tree: Dictionary in trees:
		var other: Vector2 = tree["at"]
		if at.distance_to(other) < spacing:
			return true
	return false


static func _add_parts(root: Node3D, forest: ForestData, trees: Array[Dictionary]) -> void:
	var pines := func(tree_data: Dictionary) -> bool: return not tree_data["round"]
	var rounds := func(tree_data: Dictionary) -> bool: return tree_data["round"]
	# Las mallas se comparten entre trozos.
	var trunk := _cylinder(forest.bark, TRUNK_SHAPE)
	var pine_meshes: Array[Mesh] = []
	for shape: Vector4 in PINE_PARTS:
		pine_meshes.append(_cylinder(forest.foliage, shape))
	var crown := SphereMesh.new()
	crown.material = forest.foliage
	crown.radius = CROWN_SHAPE.x
	crown.height = CROWN_SHAPE.y
	crown.radial_segments = RADIAL_SEGMENTS + 4
	crown.rings = RADIAL_SEGMENTS - 2
	var names: Array[String] = ["PineLow", "PineMid", "PineTop"]
	var chunks := _chunks(trees, forest.chunk_size)
	for chunk_index: int in chunks.size():
		var chunk_trees: Array = chunks[chunk_index]
		var chunk := Node3D.new()
		chunk.name = "Chunk%d" % chunk_index
		root.add_child(chunk)
		_add_part(chunk, "Trunks", trunk, chunk_trees, TRUNK_SHAPE.w, false)
		for index: int in PINE_PARTS.size():
			_add_part(chunk, names[index], pine_meshes[index], chunk_trees.filter(pines), PINE_PARTS[index].w, true)
		_add_part(chunk, "RoundCrowns", crown, chunk_trees.filter(rounds), CROWN_SHAPE.w, true)


## Cuántos árboles dibuja la parte [param part_name] ([code]Trunks[/code], [code]PineLow[/code]…)
## en todos los trozos del bosque [param forest_root].
static func count_instances(forest_root: Node, part_name: String) -> int:
	var total := 0
	for chunk: Node in forest_root.get_children():
		var part := chunk.get_node_or_null(NodePath(part_name)) as MultiMeshInstance3D
		if part:
			total += part.multimesh.instance_count
	return total


## [param trees] repartidos en trozos de [param size] × [param size] metros (sin tamaño, uno solo).
static func _chunks(trees: Array[Dictionary], size: float) -> Array[Array]:
	var chunks: Array[Array] = []
	if size <= 0.0:
		chunks.append(trees)
		return chunks
	var by_cell: Dictionary[Vector2i, Array] = {}
	for tree: Dictionary in trees:
		var at: Vector2 = tree["at"]
		var cell := Vector2i(floori(at.x / size), floori(at.y / size))
		if not by_cell.has(cell):
			by_cell[cell] = []
		by_cell[cell].append(tree)
	chunks.assign(by_cell.values())
	return chunks


static func _add_part(root: Node3D, part_name: String, mesh: Mesh, chosen: Array, height: float, colored: bool) -> void:
	if chosen.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = colored
	multimesh.mesh = mesh
	multimesh.instance_count = chosen.size()
	for index: int in chosen.size():
		var tree: Dictionary = chosen[index]
		var size: float = tree["scale"]
		var at: Vector2 = tree["at"]
		var yaw: float = tree["yaw"]
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size)
		multimesh.set_instance_transform(index, Transform3D(basis, Vector3(at.x, height * size, at.y)))
		if colored:
			var color: Color = tree["color"]
			multimesh.set_instance_color(index, color)
	var instance := MultiMeshInstance3D.new()
	instance.name = part_name
	instance.multimesh = multimesh
	root.add_child(instance)


static func _add_colliders(root: Node3D, forest: ForestData, trees: Array[Dictionary]) -> void:
	var body := StaticBody3D.new()
	body.name = "TreeColliders"
	body.collision_mask = 0
	root.add_child(body)
	var shape := CylinderShape3D.new()
	shape.radius = forest.trunk_radius
	shape.height = forest.trunk_height
	for tree: Dictionary in trees:
		if not tree["collides"]:
			continue
		var at: Vector2 = tree["at"]
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.position = Vector3(at.x, forest.trunk_height * 0.5, at.y)
		body.add_child(collider)


## Cilindro (o cono, con radio de arriba 0) de [param shape]: radio arriba, radio abajo y alto.
static func _cylinder(material: Material, shape: Vector4) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.material = material
	mesh.top_radius = shape.x
	mesh.bottom_radius = shape.y
	mesh.height = shape.z
	mesh.radial_segments = RADIAL_SEGMENTS
	mesh.rings = 1
	return mesh
