extends GutTest
## Menú principal: de fondo, una tragaperras y un cofre; Opciones, junto al idioma; «Jugar» lo pide,
## los récords están a la derecha y «Opciones» y «Archivo» cambian el menú y los récords por su panel (y al cerrarlo vuelven).

const MenuScene := preload("res://ui/menus/main/main_menu.tscn")

var _menu: MainMenu


func before_each() -> void:
	_menu = MenuScene.instantiate() as MainMenu
	add_child_autofree(_menu)


func test_the_background_has_a_slot_machine_and_a_chest() -> void:
	assert_true(_menu.find_child("SlotMachine", true, false) is SlotMachine)
	assert_true(_menu.find_child("Chest", true, false) is Chest)


func test_options_sit_next_to_the_language() -> void:
	var options := _menu.get_node(^"%Options") as Node
	assert_eq(options.get_parent(), (_menu.get_node(^"%LanguagePicker") as Node).get_parent())
	assert_null(_menu.find_child("Achievements", true, false), "los logros son las misiones")


func test_play_asks_to_play() -> void:
	watch_signals(_menu)
	(_menu.get_node(^"%Play") as Button).pressed.emit()
	assert_signal_emitted(_menu, "play_requested")


func test_options_replace_the_menu() -> void:
	(_menu.get_node(^"%Options") as Button).pressed.emit()
	assert_true((_menu.get_node(^"%OptionsPanel") as OptionsPanel).visible)
	assert_false((_menu.get_node(^"%Menu") as Control).visible)


func test_the_archive_replaces_the_menu_and_comes_back() -> void:
	var archive := _menu.get_node(^"%ArchivePanel") as ArchivePanel
	(_menu.get_node(^"%Archive") as Button).pressed.emit()
	assert_true(archive.visible)
	assert_false((_menu.get_node(^"%Right") as Control).visible, "los récords también se van")
	assert_false((_menu.get_node(^"%Menu") as Control).visible)
	archive.close()
	assert_true((_menu.get_node(^"%Menu") as Control).visible)
	assert_true((_menu.get_node(^"%Right") as Control).visible)


func test_the_records_are_always_on_the_right() -> void:
	assert_true((_menu.get_node(^"%LeaderboardPanel") as LeaderboardPanel).visible)
	assert_true((_menu.get_node(^"%Right") as Control).visible)


func test_choosing_a_run_opens_its_detail_apart() -> void:
	var detail := _menu.get_node(^"%RunDetailPanel") as RunDetailPanel
	var records := _menu.get_node(^"%LeaderboardPanel") as LeaderboardPanel
	var record := RunRecord.new()
	record.kills = 12
	records.run_chosen.emit(record)
	assert_true(detail.visible)
	assert_false((_menu.get_node(^"%Menu") as Control).visible)
	assert_false((_menu.get_node(^"%Right") as Control).visible)
	detail.close()
	assert_true((_menu.get_node(^"%Menu") as Control).visible)
	assert_true((_menu.get_node(^"%Right") as Control).visible)
