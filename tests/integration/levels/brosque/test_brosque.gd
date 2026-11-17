extends GutTest
## El Brosque: las oleadas empiezan solas, el jugador aparece en el claro, dentro de las paredes los
## árboles chocan y fuera una banda de bosque tapa el borde; los enemigos salen solo dentro y el
## nivel da la bienvenida.

const BrosqueScene := preload("res://levels/brosque/brosque.tscn")

var _level: Node3D


func before_all() -> void:
	RunState.character = null
	_level = BrosqueScene.instantiate() as Node3D
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


func test_the_trees_inside_the_walls_collide_and_the_outer_forest_hides_the_edge() -> void:
	var trunks := (_level.get_node(^"Forest/Trunks") as MultiMeshInstance3D).multimesh.instance_count
	var colliders := _level.get_node(^"Forest/TreeColliders").get_children()
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
