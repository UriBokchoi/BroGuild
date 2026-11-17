extends GutTest
## Pantalla de resultados: al morir el jugador y tras su espera, pausa y muestra lo apuntado por el
## RunRecorder bajo una frase de muerte al azar, con el foco en «Reintentar» (que lleva su tecla);
## Esc no la cierra.

const PanelScene := preload("res://ui/menus/results/results_panel.tscn")

var _recorder: RunRecorder
var _panel: ResultsPanel


func before_each() -> void:
	_recorder = RunRecorder.new()
	add_child_autofree(_recorder)
	_panel = PanelScene.instantiate() as ResultsPanel
	_panel.recorder = _recorder
	_panel.delay = 0.1
	add_child_autofree(_panel)


func after_each() -> void:
	# Nunca dejar el árbol en pausa: GUT se quedaría parado.
	get_tree().paused = false


func test_hidden_while_alive() -> void:
	assert_false(_panel.is_open())


func test_opens_after_the_player_dies() -> void:
	EventBus.player_died.emit()
	assert_false(_panel.is_open(), "espera un momento")
	# Temporizador que corre en pausa: el panel pausa el árbol al abrirse y GUT esperaría para siempre.
	await get_tree().create_timer(0.3, true).timeout
	assert_true(_panel.is_open())
	assert_true(get_tree().paused)


func test_shows_what_the_recorder_saw() -> void:
	_recorder.stats.seconds = 125.0
	_recorder.stats.level = 12
	_recorder.stats.kills = 340
	_recorder.stats.elite_kills = 4
	_recorder.stats.gold_earned = 57.6
	_recorder.stats.damage_dealt = 9876.5
	_panel.open()
	var rows := _panel.get_rows()
	assert_eq(rows["RESULTS_TIME"], "2:05")
	assert_eq(rows["RESULTS_LEVEL"], "12")
	assert_eq(rows["RESULTS_KILLS"], "340")
	assert_eq(rows["RESULTS_ELITE_KILLS"], "4")
	assert_eq(rows["RESULTS_GOLD"], "57")
	assert_eq(rows["RESULTS_DAMAGE"], "9876")


func test_retry_has_focus_and_shows_its_key() -> void:
	_panel.open()
	var retry := _panel.get_node(^"%Retry") as Button
	assert_true(retry.has_focus())
	assert_string_contains(retry.text, InteractionPrompt.key_text(InputActions.RETRY))


func test_escape_does_not_close_it() -> void:
	_panel.open()
	var escape := InputEventAction.new()
	escape.action = InputActions.PAUSE
	escape.pressed = true
	_panel._input(escape)
	assert_true(_panel.is_open())


func test_shows_a_random_death_line() -> void:
	assert_gt(_panel.death_lines.size(), 1, "varias frases")
	var seen: Dictionary[String, bool] = {}
	for _death: int in 30:
		_panel.open()
		var title := (_panel.get_node(^"%Title") as Label).text
		assert_has(_panel.death_lines, StringName(title), "una de su lista")
		seen[title] = true
	assert_gt(seen.size(), 1, "no siempre la misma")


func test_every_death_line_is_translated() -> void:
	for line: StringName in _panel.death_lines:
		assert_ne(TranslationServer.translate(line), line, "«%s» sin traducir" % line)
