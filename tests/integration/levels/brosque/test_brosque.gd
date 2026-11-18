extends GutTest
## El Brosque: las oleadas empiezan solas, el jugador aparece en el claro, el mapa se genera al
## cargar (mesetas, tragaperras, cofres, props y bosque; dentro de las paredes los árboles chocan y
## fuera una banda tapa el borde), los enemigos salen solo dentro, el nivel da la bienvenida y tiene
## su jefe: el altar al borde del claro y las tarjetas de socio justas, lejos del punto de aparición; y
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
	assert_eq(slots.size(), 4, "una en el suelo y tres encima de mesetas")
	assert_gt(layout.get_pieces().size(), slots.size())


func test_the_map_has_chests_on_the_ground_and_on_plateaus() -> void:
	var layout := _level.get_node(^"Layout") as LevelLayout
	var chests := layout.get_pieces().filter(func(piece: Node3D) -> bool: return piece is Chest)
	assert_eq(chests.size(), 7, "cinco en el suelo y dos en las mesetas que quedan")
	var high := chests.filter(func(chest: Node3D) -> bool: return chest.position.y > 0.0)
	assert_eq(high.size(), 2)


func test_the_trees_inside_the_walls_collide_and_the_outer_forest_hides_the_edge() -> void:
	var trunks := (_level.get_node(^"Layout/Forest/Trunks") as MultiMeshInstance3D).multimesh.instance_count
	var colliders := _level.get_node(^"Layout/Forest/TreeColliders").get_children()
	assert_gt(colliders.size(), 0)
	assert_gt(trunks, colliders.size() * 3, "la banda de fuera es mucho más grande")
	for collider: Node in colliders:
		var at := (collider as Node3D).position
		assert_lt(maxf(absf(at.x), absf(at.z)), 81.0, "solo chocan los de dentro de las paredes")


func test_enemies_only_spawn_inside_the_walls() -> void:
	var systems := _level.get_node(^"RunSystems") as RunSystems
	assert_true(systems.director.play_area.has_area())
	assert_lt(systems.director.play_area.end.x, 81.0)


func test_it_says_welcome() -> void:
	var systems := _level.get_node(^"RunSystems") as RunSystems
	assert_has(systems.intro_keys, &"BROSQUE_INTRO_WELCOME")


func test_it_has_its_boss_altar_and_membership_cards() -> void:
	var systems := _level.get_node(^"RunSystems") as RunSystems
	assert_not_null(systems.boss)
	assert_same(systems.encounter.data, systems.boss)
	var layout := _level.get_node(^"Layout") as LevelLayout
	var altars := layout.get_pieces().filter(func(piece: Node3D) -> bool: return piece is BossAltar)
	assert_eq(altars.size(), 1)
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
	assert_eq(ruins.size(), 6, "un templo, tres muros y dos arcos")
	for ruin: Node3D in ruins:
		assert_gt(Vector2(ruin.position.x, ruin.position.z).length(), 18.0, "fuera del claro")


func test_the_tavern_stands_in_the_middle_of_a_wall_facing_inside() -> void:
	var tavern := _level.get_node(^"Tavern") as HealShop
	assert_not_null(tavern)
	assert_almost_eq(tavern.position.x, 0.0, 0.01, "en el centro de la pared")
	assert_gt(absf(tavern.position.z), 75.0, "en la pared del borde")
	assert_gt((-tavern.basis.z).dot(-tavern.position.normalized()), 0.99, "mirando hacia dentro")


func test_puddles_with_a_flower_are_only_decoration() -> void:
	await wait_physics_frames(2)
	var puddles := _level.get_node(^"Puddles").get_children()
	assert_gt(puddles.size(), 8, "repartidos por el suelo")
	for puddle: Node in puddles:
		assert_eq(puddle.find_children("*", "CollisionObject3D", true, false).size(), 0, "ni chocan ni se usan")
