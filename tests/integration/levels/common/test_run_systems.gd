extends GutTest
## RunSystems: pone al jugador en el punto de aparición con el personaje de serie del nivel, da sus
## oleadas al director y las empieza solas si el nivel lo pide.

const SystemsScene := preload("res://levels/common/run_systems.tscn")
const WAVES := preload("res://data/waves/brosque.tres")
const WARRIOR := preload("res://data/characters/warrior.tres")
const SPAWN := Vector3(5.0, 0.0, 7.0)

var _systems: RunSystems


func before_each() -> void:
	RunState.character = null
	var level := Node3D.new()
	var spawn := Marker3D.new()
	spawn.position = SPAWN
	level.add_child(spawn)
	_systems = SystemsScene.instantiate() as RunSystems
	_systems.waves = WAVES
	_systems.autostart_waves = true
	_systems.default_character = WARRIOR
	_systems.spawn_point = spawn
	level.add_child(_systems)
	add_child_autofree(level)


func after_each() -> void:
	RunState.character = null


func test_the_player_appears_at_the_spawn_point() -> void:
	assert_almost_eq(_systems.player.global_position, SPAWN, Vector3.ONE * 0.01)


func test_the_player_gets_the_level_character() -> void:
	assert_same(_systems.player.character, WARRIOR)


func test_the_waves_are_the_level_ones_and_start_alone() -> void:
	assert_same(_systems.director.data, WAVES)
	assert_true(_systems.director.is_running())
