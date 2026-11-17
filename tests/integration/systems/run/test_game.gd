extends GutTest
## Game: empieza en el menú principal; «Jugar» carga el nivel y empieza la partida; reintentar
## carga otra vez el nivel; volver al menú termina la partida. Pausa y resultados llegan por
## RunFlow. Con un nivel de prueba vacío.

const GameScene := preload("res://systems/run/game.tscn")
const TestLevelScene := preload("res://tests/integration/systems/run/game_test_level.tscn")

var _game: Game
var _level: LevelData


func before_each() -> void:
	RunState.level = null
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


func test_starts_in_the_main_menu() -> void:
	assert_true(_game.get_screen() is MainMenu)
	assert_false(RunState.is_running)


func test_play_loads_the_level_and_starts_the_run() -> void:
	(_game.get_screen() as MainMenu).play_requested.emit()
	await wait_process_frames(1)
	assert_eq(_game.get_screen().scene_file_path, TestLevelScene.resource_path)
	assert_same(RunState.level, _level)
	assert_true(RunState.is_running)


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
