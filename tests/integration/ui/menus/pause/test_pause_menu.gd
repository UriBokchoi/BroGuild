extends GutTest
## Menú de pausa: Esc lo abre y lo cierra pausando el juego, y muestra todas las stats del
## jugador, resaltando las modificadas.

const PlayerScene := preload("res://entities/player/player.tscn")
const MenuScene := preload("res://ui/menus/pause/pause_menu.tscn")

var _player: Player
var _menu: PauseMenu


func before_each() -> void:
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_menu = MenuScene.instantiate() as PauseMenu
	_menu.player = _player
	add_child_autofree(_menu)


func after_each() -> void:
	# Nunca dejar el árbol en pausa: GUT se quedaría parado.
	get_tree().paused = false


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


func test_options_is_disabled_for_now() -> void:
	var options := _menu.get_node(^"Margin/Layout/Menu/Options") as Button
	assert_true(options.disabled)


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
