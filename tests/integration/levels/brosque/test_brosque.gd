extends GutTest
## El Brosque: las oleadas empiezan solas, el jugador aparece en el claro, el mapa se genera al
## cargar (mesetas, tragaperras, cofres, props y bosque; dentro de las paredes los árboles chocan y
## fuera una banda tapa el borde), los enemigos salen solo dentro, el nivel da la bienvenida y tiene
## su jefe: el portal al borde del claro y las tarjetas de socio justas, lejos del punto de aparición; y
## unas ruinas pequeñas fuera del claro.

const BrosqueScene := preload("res://levels/brosque/brosque.tscn")

var _level: Node3D


func before_all() -> void:
	RunState.character = null
	_level = BrosqueScene.instantiate() as Node3D
	var layout := _level.get_node(^"Layout") as LevelLayout
	layout.rng = RandomNumberGenerator.new()
	layout.rng.seed = 17
	add_child(_level)


func after_all() -> void:
	_level.free()
	RunState.character = null


## Distancia del centro a la cara de dentro de las paredes (la del borde que se ve).
func _wall() -> float:
	return (_level.get_node(^"MapBoundary") as MapBoundary).half_extent.x


## Cuántas piezas del mapa tienen [param marker] en su escena (o son de esa clase), según los datos.
func _count_in_data(marker: String) -> int:
	var data := (_level.get_node(^"Layout") as LevelLayout).data
	var total := 0
	var all_pieces: Array[LayoutPiece] = []
	all_pieces.append_array(data.pieces)
	all_pieces.append_array(data.top_pieces)
	for piece: LayoutPiece in all_pieces:
		var path := piece.scene.resource_path
		var matches := path.contains(marker)
		if not matches:
			var root := piece.scene.instantiate()
			matches = root.is_class(marker) or (root.get_script() and (root.get_script() as Script).get_global_name() == marker)
			root.free()
		if matches:
			total += piece.count
	return total


func test_the_waves_start_alone() -> void:
	var systems := _level.get_node(^"RunSystems") as RunSystems
	assert_true(systems.director.is_running())


func test_the_player_appears_in_the_clearing() -> void:
	var systems := _level.get_node(^"RunSystems") as RunSystems
	var spawn := _level.get_node(^"PlayerSpawn") as Node3D
	assert_almost_eq(systems.player.global_position, spawn.global_position, Vector3.ONE * 0.01)


func test_the_map_is_generated_with_its_slot_machines() -> void:
	var layout := _level.get_node(^"Layout") as LevelLayout
	var slots := layout.get_pieces().filter(func(piece: Node3D) -> bool: return piece is SlotMachine)
	assert_eq(slots.size(), _count_in_data("SlotMachine"), "en el suelo y encima de mesetas, las de los datos")
	assert_gt(layout.get_pieces().size(), slots.size())


func test_the_map_has_chests_on_the_ground_and_on_plateaus() -> void:
	var layout := _level.get_node(^"Layout") as LevelLayout
	var chests := layout.get_pieces().filter(func(piece: Node3D) -> bool: return piece is Chest)
	assert_eq(chests.size(), _count_in_data("Chest"), "en el suelo y en las mesetas, los de los datos")
	var high := chests.filter(func(chest: Node3D) -> bool: return chest.position.y > 0.0)
	assert_gt(high.size(), 0, "alguno encima de una meseta")


func test_the_trees_inside_the_walls_collide_and_the_outer_forest_hides_the_edge() -> void:
	var trunks := ForestBuilder.count_instances(_level.get_node(^"Layout/Forest"), "Trunks")
	var colliders := _level.get_node(^"Layout/Forest/TreeColliders").get_children()
	assert_gt(colliders.size(), 0)
	assert_gt(trunks, colliders.size() * 3, "la banda de fuera es mucho más grande")
	for collider: Node in colliders:
		var at := (collider as Node3D).position
		assert_lt(maxf(absf(at.x), absf(at.z)), _wall() + 1.0, "solo chocan los de dentro de las paredes")


func test_the_visible_edge_lies_on_the_inner_face_of_the_walls() -> void:
	var boundary := _level.get_node(^"MapBoundary") as MapBoundary
	assert_same(boundary.target, _level.get_node(^"RunSystems/Player"), "brilla alrededor del jugador")
	for wall: Node in _level.get_node(^"Bounds").get_children():
		var shape := wall as CollisionShape3D
		var size := (shape.shape as BoxShape3D).size
		var at := shape.position
		if absf(at.x) > absf(at.z):
			assert_almost_eq(absf(at.x) - size.x / 2.0, boundary.half_extent.x, 0.01, "%s" % wall.name)
		else:
			assert_almost_eq(absf(at.z) - size.z / 2.0, boundary.half_extent.y, 0.01, "%s" % wall.name)


func test_the_forest_is_drawn_in_chunks() -> void:
	var forest := _level.get_node(^"Layout/Forest")
	var data := (_level.get_node(^"Layout") as LevelLayout).data.forest
	var chunks := forest.get_children().filter(func(node: Node) -> bool: return node.name.begins_with("Chunk"))
	assert_gt(chunks.size(), 10, "muchos trozos: los que no se ven no se dibujan")
	for chunk: Node in chunks:
		var trunks := chunk.get_node_or_null(^"Trunks") as MultiMeshInstance3D
		assert_not_null(trunks, "%s tiene árboles" % chunk.name)
		var box := trunks.multimesh.get_aabb()
		assert_lt(box.size.x, data.chunk_size + 2.0, "%s cabe en su trozo" % chunk.name)
		assert_lt(box.size.z, data.chunk_size + 2.0)


func test_the_canopies_drop_leaves_around_the_player() -> void:
	var leaves := _level.get_node(^"CanopyLeaves") as CanopyLeaves
	assert_same(leaves.target, _level.get_node(^"RunSystems/Player"))
	assert_gt(leaves.tree_count(), 50, "conoce las copas de los árboles de dentro")


func test_enemies_only_spawn_inside_the_walls() -> void:
	var systems := _level.get_node(^"RunSystems") as RunSystems
	assert_true(systems.director.play_area.has_area())
	assert_lt(systems.director.play_area.end.x, _wall())
	assert_gt(systems.director.play_area.end.x, _wall() - 15.0, "casi hasta la pared")


func test_it_says_welcome() -> void:
	var systems := _level.get_node(^"RunSystems") as RunSystems
	assert_has(systems.intro_keys, &"BROSQUE_INTRO_WELCOME")


func test_it_has_its_boss_portal_and_membership_cards() -> void:
	var systems := _level.get_node(^"RunSystems") as RunSystems
	assert_not_null(systems.boss)
	assert_same(systems.encounter.data, systems.boss)
	var layout := _level.get_node(^"Layout") as LevelLayout
	var portals := layout.get_pieces().filter(func(piece: Node3D) -> bool: return piece is BossPortal)
	assert_eq(portals.size(), 1)
	# Las tarjetas se reparten un tick de física después de cargar.
	await wait_physics_frames(2)
	var keys := _level.get_node(^"BossKeys").get_children()
	assert_eq(keys.size(), systems.boss.keys_needed, "las justas: ni una de más")
	for key: Node in keys:
		var at := (key as Node3D).global_position
		assert_gte(Vector2(at.x, at.z).length(), 25.0, "lejos del punto de aparición")


func test_it_has_small_ruins() -> void:
	var layout := _level.get_node(^"Layout") as LevelLayout
	var ruins := layout.get_pieces().filter(func(piece: Node3D) -> bool: return piece.scene_file_path.contains("/ruin_"))
	assert_eq(ruins.size(), _count_in_data("/ruin_"), "templos, muros y arcos, los de los datos")
	for ruin: Node3D in ruins:
		assert_gt(Vector2(ruin.position.x, ruin.position.z).length(), 18.0, "fuera del claro")


func test_the_tavern_stands_in_the_middle_of_a_wall_facing_inside() -> void:
	var tavern := _level.get_node(^"Tavern") as HealShop
	assert_not_null(tavern)
	assert_almost_eq(tavern.position.x, 0.0, 0.01, "en el centro de la pared")
	assert_gt(absf(tavern.position.z), _wall() - 5.0, "en la pared del borde")
	assert_gt((-tavern.basis.z).dot(-tavern.position.normalized()), 0.99, "mirando hacia dentro")


func test_the_map_is_bigger_than_the_first_one() -> void:
	assert_almost_eq(_wall(), 110.0, 0.01, "paredes a 110 m del centro (antes, 80)")
	var layout := _level.get_node(^"Layout") as LevelLayout
	var far := layout.get_pieces().filter(func(piece: Node3D) -> bool:
		return maxf(absf(piece.position.x), absf(piece.position.z)) > 75.0)
	assert_gt(far.size(), 0, "hay piezas donde antes estaba la pared")


func test_the_dumbbells_are_charge_shrines() -> void:
	var layout := _level.get_node(^"Layout") as LevelLayout
	var shrines := layout.get_pieces().filter(func(piece: Node3D) -> bool: return piece is ChargeShrine)
	assert_eq(shrines.size(), _count_in_data("ChargeShrine"))
	assert_gt(shrines.size(), 0)
	assert_not_null(_level.get_node(^"RunSystems/StatChoicePanel"), "y quien enseña lo que ofrecen")


func test_puddles_with_a_flower_are_only_decoration() -> void:
	await wait_physics_frames(2)
	var puddles := _level.get_node(^"Puddles").get_children()
	assert_gt(puddles.size(), 8, "repartidos por el suelo")
	for puddle: Node in puddles:
		assert_eq(puddle.find_children("*", "CollisionObject3D", true, false).size(), 0, "ni chocan ni se usan")


func test_it_has_mushroom_rings() -> void:
	var layout := _level.get_node(^"Layout") as LevelLayout
	var rings := layout.get_pieces().filter(func(piece: Node3D) -> bool: return piece is ChoiceShrine)
	assert_eq(rings.size(), _count_in_data("ChoiceShrine"), "los de los datos")
