extends GutTest
## Menú principal: viste a los personajes de fondo, «Jugar» lo pide, «Opciones» y «Récords» cambian
## el menú por su panel (y al cerrarlo vuelve) y «Archivo» está desactivado hasta que exista.

const MenuScene := preload("res://ui/menus/main/main_menu.tscn")

var _menu: MainMenu


func before_each() -> void:
	_menu = MenuScene.instantiate() as MainMenu
	add_child_autofree(_menu)


func test_dresses_the_characters() -> void:
	for index: int in _menu.models.size():
		assert_eq(_menu.models[index].get_color(), _menu.characters[index].color)


func test_play_asks_to_play() -> void:
	watch_signals(_menu)
	(_menu.get_node(^"%Play") as Button).pressed.emit()
	assert_signal_emitted(_menu, "play_requested")


func test_options_replace_the_menu() -> void:
	(_menu.get_node(^"%Options") as Button).pressed.emit()
	assert_true((_menu.get_node(^"%OptionsPanel") as OptionsPanel).visible)
	assert_false((_menu.get_node(^"%Menu") as Control).visible)


func test_records_replace_the_menu_and_come_back() -> void:
	var records := _menu.get_node(^"%LeaderboardPanel") as LeaderboardPanel
	(_menu.get_node(^"%Records") as Button).pressed.emit()
	assert_true(records.visible)
	assert_false((_menu.get_node(^"%Menu") as Control).visible)
	records.close()
	assert_true((_menu.get_node(^"%Menu") as Control).visible)


func test_the_archive_is_not_ready_yet() -> void:
	assert_true((_menu.get_node(^"%Archive") as Button).disabled)
