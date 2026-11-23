extends GutTest
## Los trolls de piedra del Brosque: dos modelos del Trolleador pintados de piedra (el musgo y la olla
## conservan el suyo), fuera de la pared este y dentro de un claro reservado del bosque, para que se
## vean desde dentro.

const STONE_TROLLS := preload("res://levels/brosque/props/stone_trolls.tscn")
const BROSQUE := preload("res://levels/brosque/brosque.tscn")
const LAYOUT := preload("res://data/layouts/brosque.tres")
## Distancia al centro de las paredes invisibles del Brosque.
const WALL := 81.0


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
	var level := BROSQUE.instantiate()
	var trolls := level.get_node(^"StoneTrolls") as Node3D
	var at := trolls.position
	assert_gt(at.x, WALL, "fuera de la pared este")
	var cleared := false
	for zone: Vector3 in LAYOUT.reserved:
		if Vector2(at.x - zone.x, at.z - zone.y).length() < zone.z:
			cleared = true
	assert_true(cleared, "en un claro reservado del bosque")
	level.free()
