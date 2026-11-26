extends GutTest
## Pestaña «Mejoras»: una fila por mejora con su nivel y su precio; comprar cobra las bro-monedas y
## lo guarda (sin monedas, el botón está apagado); «Reembolsar todo» lo devuelve. Esc la cierra. En
## el menú principal, «Mejoras» la abre en lugar de la lista y los récords.

const PanelScene := preload("res://ui/menus/upgrades/upgrades_panel.tscn")
const MenuScene := preload("res://ui/menus/main/main_menu.tscn")

var _panel: UpgradesPanel


func before_each() -> void:
	# Los tests usan un perfil de prueba (hook): se empieza de cero.
	Save.profile = PlayerProfile.new()
	_panel = PanelScene.instantiate() as UpgradesPanel
	add_child_autofree(_panel)


func after_each() -> void:
	Save.profile = PlayerProfile.new()
	Save.save_profile()


func test_shows_one_row_per_upgrade() -> void:
	_panel.open()
	assert_true(_panel.visible)
	assert_eq(_panel.get_rows().size(), _panel.catalog.upgrades.size())
	assert_eq((_panel.get_node(^"%Coins") as Label).text, "0")


func test_without_coins_nothing_can_be_bought() -> void:
	_panel.open()
	for row: UpgradeRow in _panel.get_rows():
		assert_true(row.get_buy_button().disabled, "%s: sin monedas" % row.upgrade.id)
	assert_true((_panel.get_node(^"%Refund") as Button).disabled, "nada que reembolsar")


func test_buying_charges_and_saves() -> void:
	Save.profile.add_bro_coins(100)
	_panel.open()
	var row := _panel.get_rows()[0]
	assert_false(row.get_buy_button().disabled)
	row.get_buy_button().pressed.emit()
	var cost := row.upgrade.cost_of(1)
	assert_eq(Save.profile.bro_coins, 100 - cost)
	assert_eq(Save.profile.level_of(row.upgrade.id), 1)
	assert_eq((_panel.get_node(^"%Coins") as Label).text, str(100 - cost))
	Save.load_profile()
	assert_eq(Save.profile.level_of(row.upgrade.id), 1, "guardado")


func test_refund_gives_the_coins_back() -> void:
	Save.profile.add_bro_coins(100)
	_panel.open()
	var upgrade := _panel.catalog.upgrades[0]
	_panel.buy(upgrade)
	_panel.buy(upgrade)
	assert_false((_panel.get_node(^"%Refund") as Button).disabled)
	assert_eq(_panel.refund(), upgrade.spent_up_to(2))
	assert_eq(Save.profile.bro_coins, 100)
	assert_eq(Save.profile.level_of(upgrade.id), 0)
	assert_true((_panel.get_node(^"%Refunded") as Label).visible, "dice cuántas")


func test_escape_closes_it() -> void:
	_panel.open()
	watch_signals(_panel)
	var event := InputEventAction.new()
	event.action = InputActions.PAUSE
	event.pressed = true
	_panel._unhandled_input(event)
	assert_false(_panel.visible)
	assert_signal_emitted(_panel, "closed")


func test_the_main_menu_opens_it() -> void:
	var menu := MenuScene.instantiate() as MainMenu
	add_child_autofree(menu)
	var panel := menu.get_node(^"%UpgradesPanel") as UpgradesPanel
	(menu.get_node(^"%Upgrades") as Button).pressed.emit()
	assert_true(panel.visible)
	assert_false((menu.get_node(^"%Menu") as Control).visible)
	assert_false((menu.get_node(^"%Right") as Control).visible)
	panel.close()
	assert_true((menu.get_node(^"%Menu") as Control).visible)
