extends GutTest
## Panel de récords: sin partidas avisa de que no hay; con ellas, una fila por partida (de la mejor a
## la peor) bajo las cabeceras, con la última jugada resaltada. «Volver» y Esc lo cierran.

const PanelScene := preload("res://ui/menus/leaderboard/leaderboard_panel.tscn")
const WARRIOR := preload("res://data/characters/warrior.tres")
const BROSQUE := preload("res://data/levels/brosque.tres")
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


func test_starts_hidden() -> void:
	assert_false(_panel.visible)


func test_without_runs_says_so() -> void:
	_panel.open()
	assert_true(_panel.visible)
	assert_true((_panel.get_node(^"%Empty") as Label).visible)
	assert_eq(_panel.get_rows().size(), 0)


func test_lists_the_runs_best_first() -> void:
	_record(40, false, 1.0)
	_record(300, true, 2.0)
	_panel.open()
	assert_false((_panel.get_node(^"%Empty") as Label).visible)
	var rows := _panel.get_rows()
	assert_eq(rows.size(), 3, "cabeceras y dos partidas")
	assert_eq(rows[0], _headers())
	assert_eq(rows[1], PackedStringArray([
		"1", String(WARRIOR.name_key), "300", "2:05", "9", String(BROSQUE.name_key), "RECORDS_WON",
	]))
	assert_eq(rows[2][0], "2")
	assert_eq(rows[2][2], "40")
	assert_eq(rows[2][6], "RECORDS_LOST")


func test_highlights_the_latest_run() -> void:
	_record(300, false, 1.0)
	_record(40, false, 5.0)
	_panel.open()
	var cells := (_panel.get_node(^"%Rows") as GridContainer).get_children()
	var columns := LeaderboardPanel.COLUMNS.size()
	assert_eq((cells[columns] as Label).theme_type_variation, &"StatValueLabel", "la mejor, normal")
	assert_eq((cells[columns * 2] as Label).theme_type_variation, &"StatModifiedLabel", "la última, resaltada")


func test_unknown_character_shows_a_dash() -> void:
	var record := RunRecord.new()
	record.kills = 3
	Save.record_run(record)
	_panel.open()
	assert_eq(_panel.get_rows()[1][1], LeaderboardPanel.UNKNOWN)


func test_back_closes() -> void:
	_panel.open()
	watch_signals(_panel)
	(_panel.get_node(^"%Back") as Button).pressed.emit()
	assert_false(_panel.visible)
	assert_signal_emitted(_panel, "closed")


func test_escape_closes() -> void:
	_panel.open()
	var event := InputEventAction.new()
	event.action = InputActions.PAUSE
	event.pressed = true
	_panel._unhandled_input(event)
	assert_false(_panel.visible)


func _record(kills: int, won: bool, finished_at: float) -> void:
	var stats := RunStats.new()
	stats.kills = kills
	stats.won = won
	stats.seconds = 125.0
	stats.level = 9
	var record := RunRecord.create(stats, WARRIOR, BROSQUE)
	record.finished_at = finished_at
	Save.record_run(record)


func _headers() -> PackedStringArray:
	var headers := PackedStringArray()
	for key: StringName in LeaderboardPanel.COLUMNS:
		headers.append(String(key))
	return headers
