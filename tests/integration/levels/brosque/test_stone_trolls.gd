extends GutTest
## Los trolls de piedra del Brosque: dos modelos del Trolleador pintados de piedra (el musgo y la olla
## conservan el suyo), fuera de la pared este y dentro de un claro reservado del bosque, para que se
## vean desde dentro. En los tres tiers, que tienen las paredes más lejos.

const STONE_TROLLS := preload("res://levels/brosque/props/stone_trolls.tscn")
const MAPS: Array[PackedScene] = [
	preload("res://levels/brosque/brosque_map.tscn"),
	preload("res://levels/brosque/brosque_autumn.tscn"),
	preload("res://levels/brosque/brosque_winter.tscn"),
]


func test_two_trolls_all_made_of_stone() -> void:
	var trolls := STONE_TROLLS.instantiate() as StoneStatue
	add_child_autofree(trolls)
	assert_eq(trolls.statues.size(), 2)
	var meshes := trolls.meshes()
	assert_gt(meshes.size(), 40, "todo el modelo, cabeza y porra incluidas")
	for mesh: GeometryInstance3D in meshes:
		assert_eq(mesh.material_override, trolls.material, "%s, de piedra" % mesh.name)
	var moss := trolls.get_node(^"MossBertHead") as GeometryInstance3D
	assert_null(moss.material_override, "el musgo conserva su color")


func test_they_stand_outside_the_east_wall_in_a_clearing() -> void:
	for scene: PackedScene in MAPS:
		var level := scene.instantiate()
		var trolls := level.get_node(^"StoneTrolls") as Node3D
		var wall := (level.get_node(^"MapBoundary") as MapBoundary).half_extent.x
		var layout := (level.get_node(^"Layout") as LevelLayout).data
		var at := trolls.position
		assert_gt(at.x, wall, "%s: fuera de la pared este" % scene.resource_path.get_file())
		var cleared := false
		for zone: Vector3 in layout.reserved:
			if Vector2(at.x - zone.x, at.z - zone.y).length() < zone.z:
				cleared = true
		assert_true(cleared, "%s: en un claro reservado del bosque" % scene.resource_path.get_file())
		level.free()
