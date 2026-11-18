extends GutTest
## Archivo: una pestaña por tipo del catálogo con lo descubierto («1/3»), una casilla por entrada
## (con icono si se descubrió, «?» si no) y la ficha de cada una: lo que hace si se descubrió, y si
## no, «???» y cómo descubrirlo. «Volver» y Esc lo cierran.

const PanelScene := preload("res://ui/menus/archive/archive_panel.tscn")
const CATALOG := preload("res://data/content.tres")
const WARRIOR := preload("res://data/characters/warrior.tres")
const MAGE := preload("res://data/characters/mage.tres")
const EXCALIBRO := preload("res://data/items/excalibro.tres")
const SWARMER := preload("res://data/enemies/swarmer.tres")
const PATH := "user://test_archive_panel.cfg"

var _panel: ArchivePanel
var _real_path: String


func before_each() -> void:
	_real_path = Save.archive_path
	Save.archive_path = PATH
	Save.load_discoveries()
	Save.discoveries.discover(&"characters", &"warrior")
	Save.discoveries.discover(&"items", &"excalibro")
	Save.discoveries.discover(&"enemies", &"swarmer")
	_panel = PanelScene.instantiate() as ArchivePanel
	add_child_autofree(_panel)
	_panel.open()


func after_each() -> void:
	Save.archive_path = _real_path
	Save.load_discoveries()


func test_one_tab_per_category_with_what_was_found() -> void:
	var tabs := _panel.get_tabs()
	assert_eq(tabs.size(), CATALOG.categories.size())
	var characters := CATALOG.categories[0]
	assert_eq(tabs[0].text, tr(&"ARCHIVE_TAB") % [tr(characters.name_key), 1, characters.entries.size()])
	assert_true(tabs[0].button_pressed, "empieza en la primera")


func test_tiles_show_icons_only_for_what_was_found() -> void:
	var tiles := _panel.get_tiles()
	assert_eq(tiles.size(), CATALOG.categories[0].entries.size())
	var warrior := tiles[CATALOG.categories[0].entries.find(WARRIOR)]
	var mage := tiles[CATALOG.categories[0].entries.find(MAGE)]
	assert_eq(warrior.icon, WARRIOR.icon)
	assert_null(mage.icon)
	assert_eq(mage.text, ArchivePanel.LOCKED_TILE)


func test_a_found_character_shows_what_it_does() -> void:
	_panel.show_entry(WARRIOR)
	assert_eq((_panel.get_node(^"%DetailName") as Label).text, String(WARRIOR.name_key))
	var lines := _panel.get_detail_lines()
	for modifier: StatModifier in WARRIOR.stat_modifiers:
		assert_has(lines, ModifierFormat.describe(modifier))
	assert_has(lines, tr(&"ARCHIVE_STARTING_WEAPON") % tr(WARRIOR.starting_weapon.name_key))
	assert_has(lines, tr(&"ARCHIVE_PASSIVE") % tr(WARRIOR.passive_name_key))


func test_what_was_not_found_says_how_to_find_it() -> void:
	_panel.show_entry(MAGE)
	assert_eq((_panel.get_node(^"%DetailName") as Label).text, "ARCHIVE_LOCKED")
	assert_eq((_panel.get_node(^"%DetailDescription") as Label).text, String(CATALOG.categories[0].hint_key))
	assert_eq(_panel.get_detail_lines().size(), 0)


func test_an_item_shows_its_rarity_and_effects() -> void:
	_panel.show_category(CATALOG.categories[3])
	_panel.show_entry(EXCALIBRO)
	var lines := _panel.get_detail_lines()
	assert_has(lines, String(EXCALIBRO.rarity.name_key))
	for line: String in ModifierFormat.describe_all(EXCALIBRO.stat_modifiers):
		assert_has(lines, line)


func test_an_enemy_shows_its_stats() -> void:
	var enemies := CATALOG.categories[4]
	_panel.show_category(enemies)
	_panel.show_entry(SWARMER)
	var health := SWARMER.stat_sources[0] as HealthData
	var expected := tr(&"ARCHIVE_STAT") % [tr(StatFormat.name_key(&"max_health")), StatFormat.number(health.max_health)]
	assert_has(_panel.get_detail_lines(), expected)
	assert_eq(_panel.get_detail_lines().size(), enemies.shown_stats.size())


func test_back_and_escape_close() -> void:
	watch_signals(_panel)
	(_panel.get_node(^"%Back") as Button).pressed.emit()
	assert_false(_panel.visible)
	assert_signal_emitted(_panel, "closed")
	_panel.open()
	var event := InputEventAction.new()
	event.action = InputActions.PAUSE
	event.pressed = true
	_panel._unhandled_input(event)
	assert_false(_panel.visible)
