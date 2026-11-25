extends GutTest
## Panel de subir de nivel con la ruleta: las cartas de mejora giran y se paran una tras otra; un
## clic las para todas; mientras giran no se puede volver a tirar, y luego sí si se puede pagar.
## Prepararlo al cargar lo dibuja un momento sin abrirlo, y una subida de verdad lo cancela.

const PanelScene := preload("res://ui/menus/level_up/level_up_panel.tscn")
const SWORD := preload("res://data/weapons/sword.tres")
const STAFF := preload("res://data/weapons/staff.tres")
const RARE := preload("res://data/rarities/rare.tres")

var _panel: LevelUpPanel


func before_each() -> void:
	_panel = PanelScene.instantiate() as LevelUpPanel
	add_child_autofree(_panel)


func after_each() -> void:
	get_tree().paused = false


func test_cards_stop_one_after_another() -> void:
	_panel.open(_options(), 3, &"", 10, true)
	var cards := _panel.get_cards()
	assert_true(_panel.is_spinning())
	assert_eq((_panel.get_node(^"%Subtitle") as Label).text, "LEVEL_UP_SPINNING")
	# El panel pausa el juego: temporizadores que corren en pausa.
	await get_tree().create_timer(_panel.data.spin_time + 0.05, true).timeout
	assert_false(cards[0].is_spinning(), "la primera ya")
	assert_true(cards[1].is_spinning(), "la segunda aún")
	await get_tree().create_timer(_panel.data.spin_stagger + 0.1, true).timeout
	assert_false(_panel.is_spinning())
	assert_eq((_panel.get_node(^"%Subtitle") as Label).text, "LEVEL_UP_CHOOSE")


func test_a_click_stops_them_all() -> void:
	_panel.open(_options(), 3, &"", 10, true)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_panel._input(click)
	assert_false(_panel.is_spinning())


func test_reroll_waits_for_the_wheel_and_the_gold() -> void:
	_panel.open(_options(), 3, &"", 15, true)
	assert_false(_panel.can_reroll(), "mientras gira, no")
	_panel.stop_spins()
	assert_true(_panel.can_reroll())
	assert_eq((_panel.get_node(^"%Reroll") as Button).text, tr(&"LEVEL_UP_REROLL") % 15)
	watch_signals(_panel)
	(_panel.get_node(^"%Reroll") as Button).pressed.emit()
	assert_signal_emitted(_panel, "reroll_requested")
	_panel.open(_options(), 3, &"", 15, false)
	_panel.stop_spins()
	assert_false(_panel.can_reroll(), "sin oro, no")


func test_big_cards_shrink_to_fit_the_screen() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var legendary := preload("res://data/rarities/legendary.tres")
	var options: Array[LevelUpOption] = [
		LevelUpOption.create_upgrade(SWORD, 3, SWORD.roll_upgrade(legendary, rng)),
		LevelUpOption.create_upgrade(STAFF, 3, STAFF.roll_upgrade(legendary, rng)),
		LevelUpOption.create_upgrade(SWORD, 4, SWORD.roll_upgrade(legendary, rng)),
	]
	_panel.open(options, 3, &"", 10, true)
	_panel.stop_spins()
	await get_tree().create_timer(UiMotion.DATA.appear_time + 0.1, true).timeout
	var content := _panel.appear_root
	var screen := content.get_viewport_rect()
	var xform := content.get_global_transform_with_canvas()
	var drawn := Rect2(xform * Vector2.ZERO, xform.basis_xform(content.size))
	assert_true(screen.grow(1.0).encloses(drawn), "se ve entero: %s en %s" % [drawn, screen])
	if content.size.y > screen.size.y:
		assert_lt(_panel.get_fit(), 1.0, "más alto que la pantalla: encogido")


func _options() -> Array[LevelUpOption]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var options: Array[LevelUpOption] = [
		LevelUpOption.create_upgrade(SWORD, 2, SWORD.roll_upgrade(RARE, rng)),
		LevelUpOption.create_upgrade(STAFF, 2, STAFF.roll_upgrade(RARE, rng)),
	]
	return options


func test_warming_up_draws_once_and_leaves_it_closed() -> void:
	_panel.warm_up(_options())
	assert_false(_panel.is_open(), "prepararse no es abrirse")
	assert_false(get_tree().paused, "ni pausa")
	await wait_process_frames(3)
	assert_false(_panel.visible)
	await wait_process_frames(1)
	assert_eq(_panel.get_cards().size(), 0, "sin cartas")


func test_a_real_level_up_cancels_the_warm_up() -> void:
	_panel.warm_up(_options())
	_panel.open(_options(), 3, &"", 10, true)
	await get_tree().create_timer(0.1, true).timeout
	assert_true(_panel.is_open())
	assert_true(_panel.visible, "sigue abierto y visible")
