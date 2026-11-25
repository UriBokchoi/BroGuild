extends GutTest
## Game: empieza en el menú principal; «Jugar» lleva a la selección de personaje y nivel, que carga
## el nivel y empieza la partida con lo elegido (y «Volver», al menú); reintentar carga otra vez el
## nivel; volver al menú termina la partida. Pausa y resultados llegan por RunFlow. Con un nivel de
## prueba vacío.

const GameScene := preload("res://systems/run/game.tscn")
const TestLevelScene := preload("res://tests/integration/systems/run/game_test_level.tscn")
const ROGUE := preload("res://data/characters/rogue.tres")

var _game: Game
var _level: LevelData


func before_each() -> void:
	RunState.level = null
	RunState.character = null
	_level = LevelData.new()
	_level.id = &"test"
	_level.scene = TestLevelScene
	_game = GameScene.instantiate() as Game
	_game.default_level = _level
	add_child_autofree(_game)
	await wait_process_frames(1)


func after_each() -> void:
	RunState.end_run()
	RunState.level = null
	RunState.character = null
	RunState.tier = 1


func test_starts_in_the_main_menu() -> void:
	assert_true(_game.get_screen() is MainMenu)
	assert_false(RunState.is_running)


func test_play_goes_to_the_run_setup() -> void:
	(_game.get_screen() as MainMenu).play_requested.emit()
	await wait_process_frames(1)
	assert_true(_game.get_screen() is RunSetup)


func test_the_run_setup_starts_the_run_with_its_choice() -> void:
	_game.show_run_setup()
	await wait_process_frames(1)
	(_game.get_screen() as RunSetup).play_requested.emit(ROGUE, _level, 2)
	await wait_process_frames(1)
	assert_eq(_game.get_screen().scene_file_path, TestLevelScene.resource_path)
	assert_same(RunState.level, _level)
	assert_same(RunState.character, ROGUE)
	assert_eq(RunState.tier, 2, "el tier elegido")
	assert_true(RunState.is_running)


func test_back_from_the_run_setup_goes_to_the_menu() -> void:
	_game.show_run_setup()
	await wait_process_frames(1)
	(_game.get_screen() as RunSetup).back_requested.emit()
	await wait_process_frames(1)
	assert_true(_game.get_screen() is MainMenu)


func test_retry_loads_the_level_again() -> void:
	_game.play()
	await wait_process_frames(1)
	var first := _game.get_screen()
	RunFlow.retry(get_tree())
	await wait_process_frames(1)
	assert_ne(_game.get_screen(), first, "otra instancia")
	assert_false(is_instance_valid(first), "la anterior ya no existe")
	assert_eq(_game.get_screen().scene_file_path, TestLevelScene.resource_path)


func test_back_to_the_menu_ends_the_run() -> void:
	_game.play()
	await wait_process_frames(1)
	RunFlow.to_main_menu(get_tree())
	await wait_process_frames(1)
	assert_true(_game.get_screen() is MainMenu)
	assert_false(RunState.is_running)


func test_each_run_brings_the_bought_upgrades_and_the_locked_content() -> void:
	Save.profile = PlayerProfile.new()
	Save.profile.upgrades[&"damage"] = 2
	_game.play()
	await wait_process_frames(1)
	assert_not_null(RunState.bonuses)
	assert_eq(RunState.bonuses.stat_modifiers.size(), 1, "el daño comprado")
	assert_true(RunState.locked.has(preload("res://data/weapons/hammer.tres")), "sin la misión")
	_game.retry()
	await wait_process_frames(1)
	assert_not_null(RunState.bonuses, "reintentar no las pierde")
	Save.profile = PlayerProfile.new()
	RunState.end_run()
	assert_null(RunState.bonuses, "al acabar, fuera")
