extends GutTest
## Stats con Tab: mientras se mantiene «ver stats» salen las del jugador (las mismas que en la
## pausa), al soltar se van y la rueda las desplaza. Con el juego en pausa solo salen si está abierto
## un panel de elegir (subir de nivel, un objeto), que además lo recuerda con un texto.

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
	get_tree().paused = true
	Input.action_press(InputActions.SHOW_STATS)
	await get_tree().create_timer(0.1, true).timeout
	assert_false(_overlay.is_showing(), "la pausa ya las enseña")


func test_over_a_choice_panel_even_paused() -> void:
	var panel := (load("res://ui/menus/item_choice/item_choice_panel.tscn") as PackedScene).instantiate() as ModalPanel
	add_child_autofree(panel)
	assert_eq(panel.stats_hint.text, tr(&"HUD_STATS_HINT") % InteractionPrompt.key_text(InputActions.SHOW_STATS))
	panel.visible = true
	get_tree().paused = true
	Input.action_press(InputActions.SHOW_STATS)
	await get_tree().create_timer(0.1, true).timeout
	assert_true(_overlay.is_showing(), "eligiendo, se pueden ver")
	assert_gt(_overlay.layer, panel.layer, "por encima del panel")


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
