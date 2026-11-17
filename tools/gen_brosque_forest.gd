extends SceneTree
## Genera levels/brosque/forest.tscn: los árboles del Brosque (pinos y árboles redondos de colores)
## repartidos con semilla fija, sin pisar el claro del centro ni las mesetas, más un anillo denso en
## el borde. Se dibujan con MultiMesh (pocas llamadas de dibujo) y chocan con un solo cuerpo con un
## cilindro por tronco. El resto del nivel (mesetas, props, sistemas) está en brosque.tscn y se
## edita a mano; si mueves una meseta, actualiza EXCLUSIONS y vuelve a generar:
## [code]"$G" --path . -s res://tools/gen_brosque_forest.gd[/code] (sin [code]--headless[/code]: sin
## render de verdad, los MultiMesh se guardan vacíos).

const OUTPUT := "res://levels/brosque/forest.tscn"
const SEED := 20261117
## Mitad del lado de la zona con árboles sueltos (el borde va más allá).
const HALF_SIZE := 70.0
## Distancia del anillo del borde al centro, y su grosor.
const BORDER := 74.0
const BORDER_DEPTH := 5.0
const BORDER_STEP := 4.0
const MIN_SPACING := 7.0
const MAX_TREES := 150
const ATTEMPTS := 3000
## Zonas sin árboles: centro (x, z) y radio. El claro y las mesetas de brosque.tscn.
const EXCLUSIONS: Array[Vector3] = [
	Vector3(0.0, 0.0, 20.0),
	Vector3(-38.0, -30.0, 16.0),
	Vector3(42.0, 34.0, 16.0),
	Vector3(40.0, -38.0, 21.0),
	Vector3(-36.0, 40.0, 21.0),
]
const SCALE_RANGE := Vector2(0.8, 1.4)
const ROUND_SHARE := 0.4
const ACCENT_SHARE := 0.08
const PINE_COLORS: Array[Color] = [Color(0.16, 0.46, 0.3), Color(0.13, 0.4, 0.33), Color(0.2, 0.52, 0.28)]
const ROUND_COLORS: Array[Color] = [Color(0.4, 0.66, 0.24), Color(0.5, 0.7, 0.22), Color(0.32, 0.6, 0.3)]
const ACCENT_COLORS: Array[Color] = [Color(0.9, 0.48, 0.18), Color(0.95, 0.72, 0.2)]
const BARK := preload("res://levels/brosque/materials/bark.tres")
const FOLIAGE := preload("res://levels/brosque/materials/foliage.tres")
const TRUNK_HEIGHT := 3.0
const TRUNK_RADIUS := 0.4

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = SEED
	var trees := _place_trees()
	var forest := Node3D.new()
	forest.name = "Forest"
	_add_parts(forest, trees)
	_add_colliders(forest, trees)
	var scene := PackedScene.new()
	scene.pack(forest)
	var error := ResourceSaver.save(scene, OUTPUT)
	print("árboles=", trees.size(), " save=", error)
	forest.free()
	quit(0 if error == OK else 1)


## Árboles: posición (x, z), escala, giro, si es redondo y su color.
func _place_trees() -> Array[Dictionary]:
	var trees: Array[Dictionary] = []
	for _attempt: int in ATTEMPTS:
		if trees.size() >= MAX_TREES:
			break
		var at := Vector2(_rng.randf_range(-HALF_SIZE, HALF_SIZE), _rng.randf_range(-HALF_SIZE, HALF_SIZE))
		if _excluded(at) or _too_close(at, trees):
			continue
		trees.append(_tree(at))
	var steps := floori(BORDER * 2.0 / BORDER_STEP)
	for side: int in 4:
		for step: int in steps + 1:
			var along := -BORDER + step * BORDER_STEP + _rng.randf_range(-1.0, 1.0)
			var depth := BORDER + _rng.randf_range(0.0, BORDER_DEPTH)
			var at := Vector2(along, depth) if side < 2 else Vector2(depth, along)
			if side % 2 == 1:
				at = -at
			trees.append(_tree(at))
	return trees


func _tree(at: Vector2) -> Dictionary:
	var round_tree := _rng.randf() < ROUND_SHARE
	var palette := ROUND_COLORS if round_tree else PINE_COLORS
	if _rng.randf() < ACCENT_SHARE:
		palette = ACCENT_COLORS
	return {
		"at": at,
		"scale": _rng.randf_range(SCALE_RANGE.x, SCALE_RANGE.y),
		"yaw": _rng.randf_range(0.0, TAU),
		"round": round_tree,
		"color": palette[_rng.randi_range(0, palette.size() - 1)],
	}


func _excluded(at: Vector2) -> bool:
	for zone: Vector3 in EXCLUSIONS:
		if at.distance_to(Vector2(zone.x, zone.y)) < zone.z:
			return true
	return false


func _too_close(at: Vector2, trees: Array[Dictionary]) -> bool:
	for tree: Dictionary in trees:
		var other: Vector2 = tree["at"]
		if at.distance_to(other) < MIN_SPACING:
			return true
	return false


func _add_parts(forest: Node3D, trees: Array[Dictionary]) -> void:
	_add_part(forest, "Trunks", _cylinder(BARK, 0.22, 0.36, TRUNK_HEIGHT), trees, func(_t: Dictionary) -> bool: return true, TRUNK_HEIGHT * 0.5, false)
	var pine := func(t: Dictionary) -> bool: return not t["round"]
	_add_part(forest, "PineLow", _cylinder(FOLIAGE, 0.0, 1.7, 2.4), trees, pine, 3.4, true)
	_add_part(forest, "PineMid", _cylinder(FOLIAGE, 0.0, 1.25, 2.0), trees, pine, 4.6, true)
	_add_part(forest, "PineTop", _cylinder(FOLIAGE, 0.0, 0.8, 1.6), trees, pine, 5.7, true)
	var crown := SphereMesh.new()
	crown.material = FOLIAGE
	crown.radius = 1.8
	crown.height = 3.2
	crown.radial_segments = 12
	crown.rings = 6
	_add_part(forest, "RoundCrowns", crown, trees, func(t: Dictionary) -> bool: return t["round"], 4.2, true)


func _add_part(forest: Node3D, part_name: String, mesh: Mesh, trees: Array[Dictionary], wanted: Callable, height: float, colored: bool) -> void:
	var chosen := trees.filter(wanted)
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
	forest.add_child(instance)
	instance.owner = forest


func _add_colliders(forest: Node3D, trees: Array[Dictionary]) -> void:
	var body := StaticBody3D.new()
	body.name = "TreeColliders"
	body.collision_mask = 0
	forest.add_child(body)
	body.owner = forest
	var shape := CylinderShape3D.new()
	shape.radius = TRUNK_RADIUS
	shape.height = TRUNK_HEIGHT
	for index: int in trees.size():
		var at: Vector2 = trees[index]["at"]
		var collider := CollisionShape3D.new()
		collider.name = "Trunk%d" % index
		collider.shape = shape
		collider.position = Vector3(at.x, TRUNK_HEIGHT * 0.5, at.y)
		body.add_child(collider)
		collider.owner = forest


func _cylinder(material: Material, top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.material = material
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	return mesh
