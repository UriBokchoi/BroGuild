extends GutTest
## Menú de pausa: Esc lo abre y lo cierra pausando el juego, «Opciones» abre su panel (Esc vuelve a
## la pausa) y muestra todas las stats del jugador, resaltando las modificadas.

const PlayerScene := preload("res://entities/player/player.tscn")
const MenuScene := preload("res://ui/menus/pause/pause_menu.tscn")
## Las opciones se guardan al cerrarlas: nunca en el archivo de verdad.
const TEST_SETTINGS := "user://test_pause_settings.cfg"

var _player: Player
var _menu: PauseMenu
var _settings_path: String


func before_each() -> void:
	_settings_path = Save.settings_path
	Save.settings_path = TEST_SETTINGS
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_menu = MenuScene.instantiate() as PauseMenu
	_menu.player = _player
	add_child_autofree(_menu)


func after_each() -> void:
	# Nunca dejar el árbol en pausa: GUT se quedaría parado.
	get_tree().paused = false
	Save.settings_path = _settings_path
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func test_escape_opens_and_closes_pausing_the_game() -> void:
	assert_false(_menu.visible)
	_menu._unhandled_input(_press(InputActions.PAUSE))
	assert_true(_menu.visible)
	assert_true(get_tree().paused)
	_menu._unhandled_input(_press(InputActions.PAUSE))
	assert_false(_menu.visible)
	assert_false(get_tree().paused)


func test_continue_resumes_the_game() -> void:
	_menu.open()
	(_menu.get_node(^"%Continue") as Button).pressed.emit()
	assert_false(_menu.visible)
	assert_false(get_tree().paused)


func test_options_replaces_the_menu_and_escape_goes_back() -> void:
	_menu.open()
	(_menu.get_node(^"%Options") as Button).pressed.emit()
	var options := _menu.get_node(^"%OptionsPanel") as OptionsPanel
	assert_true(options.visible)
	assert_false((_menu.get_node(^"%Layout") as Control).visible)
	# Con las opciones abiertas, la pausa no hace caso a Esc; el panel, sí.
	_menu._unhandled_input(_press(InputActions.PAUSE))
	options._unhandled_input(_press(InputActions.PAUSE))
	assert_false(options.visible, "Esc cierra las opciones")
	assert_true(_menu.visible, "y vuelve a la pausa")
	assert_true((_menu.get_node(^"%Layout") as Control).visible)
	assert_true(get_tree().paused)


func test_shows_every_player_stat() -> void:
	var view := _menu.get_node(^"%StatsView") as StatsView
	assert_eq(view.shown_stats(), _player.stats.get_stats())


func test_modified_stats_are_highlighted_when_opening() -> void:
	var view := _menu.get_node(^"%StatsView") as StatsView
	_player.stats.add_modifier(StatModifier.create(&"run_speed", StatModifier.Kind.PERCENT, 0.2), self)
	_menu.open()
	assert_true(view.is_highlighted(&"run_speed"))
	assert_false(view.is_highlighted(&"jump_height"))


func _press(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event
