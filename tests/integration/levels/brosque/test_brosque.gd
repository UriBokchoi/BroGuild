extends GutTest
## El Brosque: las oleadas empiezan solas, el jugador aparece en el claro y el bosque tiene árboles
## con un tronco que choca por cada uno.

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


func test_every_tree_has_a_trunk_that_collides() -> void:
	var trunks := (_level.get_node(^"Forest/Trunks") as MultiMeshInstance3D).multimesh.instance_count
	assert_gt(trunks, 0)
	assert_eq(_level.get_node(^"Forest/TreeColliders").get_child_count(), trunks)
