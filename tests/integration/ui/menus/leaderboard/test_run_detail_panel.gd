extends GutTest
## El detalle de una partida, en su ventana: mapa y tier, resultado, tiempo, enemigos… y la build con
## sus iconos; una partida vieja, sin build, lo dice. «Volver» y Esc la cierran.

const PanelScene := preload("res://ui/menus/leaderboard/run_detail_panel.tscn")
const WARRIOR := preload("res://data/characters/warrior.tres")
const BROSQUE := preload("res://data/levels/brosque.tres")
const SWORD := preload("res://data/weapons/sword.tres")
const CAP := preload("res://data/items/backwards_cap.tres")

var _panel: RunDetailPanel


func before_each() -> void:
	_panel = PanelScene.instantiate() as RunDetailPanel
	add_child_autofree(_panel)


func test_starts_hidden() -> void:
	assert_false(_panel.visible)


func test_shows_the_run_and_its_build() -> void:
	var record := _record(true)
	record.tier = 2
	record.weapons = {"sword": 6} as Dictionary[String, int]
	record.items = {"backwards_cap": 2} as Dictionary[String, int]
	record.pacts.append("PACT_EGO_LIFTING_NAME")
	_panel.open(record)
	assert_true(_panel.visible)
	var rows := _panel.get_rows()
	assert_eq(rows[tr(&"RECORDS_MAP")], tr(&"RECORDS_LEVEL_TIER") % [tr(BROSQUE.name_key), 2])
	assert_eq(rows[tr(&"RECORDS_RESULT")], tr(&"RECORDS_WON"))
	assert_eq(rows[tr(&"RESULTS_TIME")], "2:05")
	assert_eq(rows[tr(&"RESULTS_KILLS")], "300")
	assert_eq(_panel.get_build_names(), PackedStringArray([tr(SWORD.name_key), tr(CAP.name_key)]))


func test_an_old_run_without_build_says_so() -> void:
	_panel.open(_record(false))
	assert_eq(_panel.get_build_names().size(), 0)
	var build := _panel.get_node(^"%Build") as Node
	assert_eq((build.get_child(0) as Label).text, tr(&"RECORDS_NO_BUILD"))


func test_back_and_escape_close() -> void:
	_panel.open(_record(false))
	watch_signals(_panel)
	(_panel.get_node(^"%Back") as Button).pressed.emit()
	assert_false(_panel.visible)
	assert_signal_emitted(_panel, "closed")
	_panel.open(_record(false))
	var event := InputEventAction.new()
	event.action = InputActions.PAUSE
	event.pressed = true
	_panel._unhandled_input(event)
	assert_false(_panel.visible)


func _record(won: bool) -> RunRecord:
	var stats := RunStats.new()
	stats.kills = 300
	stats.won = won
	stats.seconds = 125.0
	stats.level = 9
	return RunRecord.create(stats, WARRIOR, BROSQUE)
