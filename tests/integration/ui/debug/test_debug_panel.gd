extends GutTest
## Panel de depuración: F3 lo muestra y lo oculta, y sus secciones actúan sobre el jugador.

const PlayerScene := preload("res://entities/player/player.tscn")
const PanelScene := preload("res://ui/debug/debug_panel.tscn")

var _player: Player
var _panel: DebugPanel


func before_each() -> void:
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_panel = PanelScene.instantiate() as DebugPanel
	_panel.player = _player
	add_child_autofree(_panel)


func test_starts_hidden_and_f3_toggles_it() -> void:
	assert_false(_panel.visible)
	_panel._unhandled_input(_press(InputActions.TOGGLE_DEBUG))
	assert_true(_panel.visible)
	_panel._unhandled_input(_press(InputActions.TOGGLE_DEBUG))
	assert_false(_panel.visible)


func test_refreshes_every_section_while_visible() -> void:
	_panel._unhandled_input(_press(InputActions.TOGGLE_DEBUG))
	await wait_process_frames(3)
	assert_true(_panel.visible, "sin errores al refrescar las secciones")


func test_stat_buttons_change_player_stats_like_an_upgrade() -> void:
	var section := _panel.get_node(^"%Sections/Stats") as StatsDebugSection
	var base := _player.stats.get_base(&"run_speed")
	section.nudge(&"run_speed", 1)
	section.nudge(&"run_speed", 1)
	var move := _player.stats.get_resolved(MovementData) as MovementData
	assert_almost_eq(move.run_speed, base * (1.0 + 2.0 * section.percent_step), 1e-6)
	section.reset()
	assert_almost_eq(move.run_speed, base, 1e-6, "reset quita los modificadores del panel")


func test_level_slider_moves_the_camera_level() -> void:
	var section := _panel.get_node(^"%Sections/Camera") as CameraDebugSection
	section.set_level(50)
	assert_eq(_player.input.camera.level, 50)


func _press(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event
