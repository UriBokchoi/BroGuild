extends GutTest
## ArchiveRecorder: apunta en el Archivo (Save) las armas y runas al conseguirlas, los objetos
## pasivos y los enemigos al derrotarlos (un élite como su enemigo), solo lo que está en el catálogo
## y solo si se le pide.

const CATALOG := preload("res://data/content.tres")
const SWORD := preload("res://data/weapons/sword.tres")
const VIGOR := preload("res://data/runes/vigor.tres")
const EXCALIBRO := preload("res://data/items/excalibro.tres")
const WARRIOR := preload("res://data/characters/warrior.tres")
const SWARMER := preload("res://data/enemies/swarmer.tres")
const SHOOTER := preload("res://data/enemies/shooter.tres")
const ELITE := preload("res://data/enemies/elite.tres")
const PATH := "user://test_archive_recorder.cfg"

var _recorder: ArchiveRecorder
var _swarm: EnemySwarm
var _real_path: String


func before_each() -> void:
	_real_path = Save.archive_path
	Save.archive_path = PATH
	Save.load_discoveries()
	_recorder = ArchiveRecorder.new()
	_recorder.catalog = CATALOG
	_recorder.record = true
	add_child_autofree(_recorder)
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)


func after_each() -> void:
	Save.archive_path = _real_path
	Save.load_discoveries()
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_weapons_and_runes_when_gained() -> void:
	EventBus.player_item_changed.emit(SWORD, 1)
	EventBus.player_item_changed.emit(VIGOR, 0)
	assert_true(Save.discoveries.has(&"weapons", &"sword"))
	assert_false(Save.discoveries.has(&"runes", &"vigor"), "perderla no la descubre")


func test_passive_items() -> void:
	EventBus.player_passive_changed.emit(EXCALIBRO, 1)
	assert_true(Save.discoveries.has(&"items", &"excalibro"))


func test_defeated_enemies_and_elites_as_their_enemy() -> void:
	_kill(_swarm.spawn(SWARMER, Vector3(-3.0, 0.0, 0.0)))
	var elite := _swarm.spawn(SHOOTER, Vector3(3.0, 0.0, 0.0))
	elite.promote(ELITE)
	_kill(elite)
	assert_true(Save.discoveries.has(&"enemies", &"swarmer"))
	assert_true(Save.discoveries.has(&"enemies", &"shooter"), "el élite cuenta como su enemigo")


func test_saves_what_is_new() -> void:
	assert_true(_recorder.discover(WARRIOR))
	assert_false(_recorder.discover(WARRIOR), "ya estaba")
	Save.load_discoveries()
	assert_true(Save.discoveries.has(&"characters", &"warrior"), "guardado en su archivo")


func test_ignores_what_is_not_in_the_catalog() -> void:
	assert_false(_recorder.discover(load("res://data/enemies/target_dummy.tres")))
	assert_false(_recorder.discover(null))


func test_does_nothing_unless_asked() -> void:
	_recorder.record = false
	EventBus.player_item_changed.emit(SWORD, 1)
	assert_false(Save.discoveries.has(&"weapons", &"sword"))


func _kill(enemy: Enemy) -> void:
	enemy.health.take_damage(DamageInfo.create(100000.0))
