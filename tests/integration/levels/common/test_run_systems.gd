extends GutTest
## RunSystems: pone al jugador en el punto de aparición con el personaje de serie del nivel, da sus
## oleadas al director y las empieza solas si el nivel lo pide. Su RunRecorder apunta las partidas
## en los récords, con el personaje del jugador, y su ArchiveRecorder apunta en el Archivo el
## personaje y su arma inicial.

const SystemsScene := preload("res://levels/common/run_systems.tscn")
const WAVES := preload("res://data/waves/brosque.tres")
const WARRIOR := preload("res://data/characters/warrior.tres")
const SPAWN := Vector3(5.0, 0.0, 7.0)
const ARCHIVE_PATH := "user://test_run_systems_archive.cfg"

var _systems: RunSystems
var _real_archive_path: String


func before_each() -> void:
	_real_archive_path = Save.archive_path
	Save.archive_path = ARCHIVE_PATH
	Save.load_discoveries()
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
	Save.archive_path = _real_archive_path
	Save.load_discoveries()
	if FileAccess.file_exists(ARCHIVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVE_PATH))


func test_the_player_appears_at_the_spawn_point() -> void:
	assert_almost_eq(_systems.player.global_position, SPAWN, Vector3.ONE * 0.01)


func test_the_player_gets_the_level_character() -> void:
	assert_same(_systems.player.character, WARRIOR)


func test_the_waves_are_the_level_ones_and_start_alone() -> void:
	assert_same(_systems.director.data, WAVES)
	assert_true(_systems.director.is_running())


func test_the_recorder_writes_down_real_runs_with_the_player() -> void:
	var recorder := _systems.get_node(^"RunRecorder") as RunRecorder
	assert_true(recorder.record_runs, "las partidas de verdad van a los récords")
	assert_same(recorder.player, _systems.player, "con el personaje del jugador")


func test_the_archive_writes_down_the_character_and_its_weapon() -> void:
	await wait_process_frames(2)
	assert_true(Save.discoveries.has(&"characters", WARRIOR.id), "el personaje, al empezar")
	assert_true(Save.discoveries.has(&"weapons", WARRIOR.starting_weapon.id), "su arma inicial")
