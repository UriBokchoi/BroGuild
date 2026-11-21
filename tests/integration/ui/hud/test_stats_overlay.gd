extends GutTest
## Stats con Tab: mientras se mantiene «ver stats» salen las del jugador (las mismas que en la
## pausa), al soltar se van, la rueda las desplaza y con el juego en pausa no salen.

const PlayerScene := preload("res://entities/player/player.tscn")
const OverlayScene := preload("res://ui/hud/stats_overlay.tscn")

var _overlay: StatsOverlay


func before_each() -> void:
	RunState.character = null
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	_overlay = OverlayScene.instantiate() as StatsOverlay
	_overlay.player = player
	add_child_autofree(_overlay)


func after_each() -> void:
	Input.action_release(InputActions.SHOW_STATS)
	get_tree().paused = false


func test_shows_while_held() -> void:
	assert_false(_overlay.is_showing())
	Input.action_press(InputActions.SHOW_STATS)
	await wait_process_frames(2)
	assert_true(_overlay.is_showing())
	assert_gt(_overlay.shown_stats().size(), 0, "con las stats del jugador")
	Input.action_release(InputActions.SHOW_STATS)
	await wait_process_frames(2)
	assert_false(_overlay.is_showing())


func test_not_while_paused() -> void:
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Input.action_press(InputActions.SHOW_STATS)
	await get_tree().create_timer(0.1, true).timeout
	assert_false(_overlay.is_showing(), "la pausa ya las enseña")


func test_the_wheel_scrolls_while_showing() -> void:
	Input.action_press(InputActions.SHOW_STATS)
	await wait_process_frames(2)
	var scroll := _overlay.get_node(^"%Scroll") as ScrollContainer
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	_overlay._unhandled_input(wheel)
	await wait_process_frames(1)
	assert_gt(scroll.scroll_vertical, 0, "baja")
