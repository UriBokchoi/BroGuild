extends GutTest
## Panel de récords (fijo en el menú principal): sin partidas avisa de que no hay; con ellas, una fila
## por partida (de la mejor a la peor) con el icono del personaje y sus enemigos, y la última jugada
## resaltada. Al hacer clic en una sale su detalle (mapa y tier, resultado, tiempo…) y su build; una
## partida vieja, sin build, lo dice.

const PanelScene := preload("res://ui/menus/leaderboard/leaderboard_panel.tscn")
const WARRIOR := preload("res://data/characters/warrior.tres")
const BROSQUE := preload("res://data/levels/brosque.tres")
const SWORD := preload("res://data/weapons/sword.tres")
const CAP := preload("res://data/items/backwards_cap.tres")
const PATH := "user://test_leaderboard_panel.cfg"

var _panel: LeaderboardPanel
var _real_path: String


func before_each() -> void:
	_real_path = Save.leaderboard_path
	Save.leaderboard_path = PATH
	Save.load_leaderboard()
	_panel = PanelScene.instantiate() as LeaderboardPanel
	add_child_autofree(_panel)


func after_each() -> void:
	Save.leaderboard_path = _real_path
	Save.load_leaderboard()
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_without_runs_says_so() -> void:
	_panel.refresh()
	assert_true((_panel.get_node(^"%Empty") as Label).visible)
	assert_eq(_panel.get_row_texts().size(), 0)
	assert_false((_panel.get_node(^"%Detail") as Control).visible, "sin detalle")


func test_lists_the_runs_best_first() -> void:
	_record(40, false, 1.0)
	_record(300, true, 2.0)
	_panel.refresh()
	assert_false((_panel.get_node(^"%Empty") as Label).visible)
	var rows := _panel.get_row_texts()
	assert_eq(rows.size(), 2)
	assert_eq(rows[0], tr(&"RECORDS_ROW") % [1, tr(WARRIOR.name_key), 300])
	assert_eq(rows[1], tr(&"RECORDS_ROW") % [2, tr(WARRIOR.name_key), 40])
	var first := (_panel.get_node(^"%List") as Node).get_child(0) as Button
	assert_eq(first.icon, WARRIOR.icon, "con el icono del personaje")


func test_highlights_the_latest_run() -> void:
	_record(300, false, 1.0)
	_record(40, false, 5.0)
	_panel.refresh()
	var list := _panel.get_node(^"%List") as Node
	assert_eq((list.get_child(0) as Button).theme_type_variation, &"RecordRow", "la mejor, normal")
	assert_eq((list.get_child(1) as Button).theme_type_variation, &"RecordRowLatest", "la última, resaltada")


func test_clicking_a_run_shows_its_detail_and_build() -> void:
	var record := _record(300, true, 2.0, false)
	record.tier = 2
	record.weapons = {"sword": 6} as Dictionary[String, int]
	record.items = {"backwards_cap": 2} as Dictionary[String, int]
	record.pacts.append("PACT_EGO_LIFTING_NAME")
	Save.record_run(record)
	_panel.refresh()
	((_panel.get_node(^"%List") as Node).get_child(0) as Button).pressed.emit()
	assert_eq(_panel.get_selected(), 0)
	assert_true((_panel.get_node(^"%Detail") as Control).visible)
	var detail := _panel.get_detail_rows()
	assert_eq(detail[tr(&"RECORDS_MAP")], tr(&"RECORDS_LEVEL_TIER") % [tr(BROSQUE.name_key), 2])
	assert_eq(detail[tr(&"RECORDS_RESULT")], tr(&"RECORDS_WON"))
	assert_eq(detail[tr(&"RESULTS_TIME")], "2:05")
	assert_eq(detail[tr(&"RESULTS_KILLS")], "300")
	assert_eq(_panel.get_build_names(), PackedStringArray([tr(SWORD.name_key), tr(CAP.name_key)]))


func test_an_old_run_without_build_says_so() -> void:
	_record(300, false, 2.0)
	_panel.refresh()
	_panel.select(0)
	assert_eq(_panel.get_build_names().size(), 0)
	var build := _panel.get_node(^"%Build") as Node
	assert_eq((build.get_child(0) as Label).text, tr(&"RECORDS_NO_BUILD"))


func test_unknown_character_shows_a_dash() -> void:
	var record := RunRecord.new()
	record.kills = 3
	Save.record_run(record)
	_panel.refresh()
	assert_eq(_panel.get_row_texts()[0], tr(&"RECORDS_ROW") % [1, LeaderboardPanel.UNKNOWN, 3])


func _record(kills: int, won: bool, finished_at: float, save: bool = true) -> RunRecord:
	var stats := RunStats.new()
	stats.kills = kills
	stats.won = won
	stats.seconds = 125.0
	stats.level = 9
	var record := RunRecord.create(stats, WARRIOR, BROSQUE)
	record.finished_at = finished_at
	if save:
		Save.record_run(record)
	return record
