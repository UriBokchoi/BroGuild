class_name ResultsPanel
extends CanvasLayer
## La pantalla del final de la partida: al morir o al ganar enseña lo que pasó (tiempo, nivel,
## enemigos, oro, daño y, si toca, el puesto en los récords) con una frase de muerte o el título de
## la victoria. «Reintentar» empieza otra partida y «Salir» vuelve al menú.
##
## La muerte se atiende al final del fotograma: si esa muerte cuenta como victoria (en la prórroga,
## con el jefe vencido), la victoria llega antes y manda.

## Quién apuntó la partida.
@export var recorder: RunRecorder
## Segundos entre la muerte y los resultados (para ver caer al jugador).
@export_range(0.0, 5.0, 0.05, "suffix:s") var delay: float = 1.0
## Segundos entre vencer al jefe y la victoria (para verlo caer y ver el premio).
@export_range(0.0, 10.0, 0.05, "suffix:s") var victory_delay: float = 4.0
## Frases de muerte (claves de traducción): sale una al azar en cada muerte.
@export var death_lines: Array[StringName] = []
## Color del fondo en la victoria (en la muerte, el de la escena).
@export var victory_tint: Color = Color(0.03, 0.1, 0.09, 0.6)

## Azar de la frase. Si no se asigna antes de entrar en el árbol, el flujo cosmético de
## [code]Rng[/code].
var rng: RandomNumberGenerator

## Ya acabó la partida (murió el jugador o cayó el jefe): lo siguiente no cambia los resultados.
var _ended: bool = false
var _death_tint: Color = Color.BLACK

@onready var _blur: ColorRect = %Blur
@onready var _content: Control = $Center/Content
@onready var _title: Label = %Title
@onready var _rows: GridContainer = %Rows
@onready var _retry: Button = %Retry
@onready var _quit: Button = %Quit


func _ready() -> void:
	visible = false
	if rng == null:
		rng = Rng.stream(Rng.Stream.COSMETIC)
	_death_tint = _tint_material().get_shader_parameter(&"tint")
	_retry.pressed.connect(retry)
	_quit.pressed.connect(_to_main_menu)
	EventBus.player_died.connect(_on_player_died)
	EventBus.run_won.connect(_on_run_won)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(InputActions.RETRY):
		get_viewport().set_input_as_handled()
		retry()
	elif event.is_action_pressed(InputActions.PAUSE):
		# Mientras se ven los resultados, Esc no abre la pausa.
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	# Al recargar el nivel con los resultados abiertos, que no deje el juego en pausa.
	if visible:
		_set_open(false)


## Muestra los resultados de una muerte con una frase al azar, pausa el juego y deja el foco en
## «Reintentar».
func open() -> void:
	var title := _title.text
	if not death_lines.is_empty():
		title = String(death_lines[rng.randi_range(0, death_lines.size() - 1)])
	_show(title, &"DeathLineLabel", _death_tint)


## Muestra los resultados de una victoria con el título [param title_key] (clave de traducción).
func open_victory(title_key: StringName) -> void:
	_show(String(title_key), &"VictoryLabel", victory_tint)


func is_open() -> bool:
	return visible


## ¿Muestra una victoria?
func is_victory() -> bool:
	return visible and _title.theme_type_variation == &"VictoryLabel"


## Empieza otra partida en el mismo nivel (reinicio rápido).
func retry() -> void:
	_set_open(false)
	RunFlow.retry(get_tree())


## Filas de resultados que muestra (pares nombre y valor; para tests).
func get_rows() -> Dictionary[String, String]:
	var rows: Dictionary[String, String] = {}
	var cells := _rows.get_children()
	for index: int in range(0, cells.size() - 1, 2):
		rows[(cells[index] as Label).text] = (cells[index + 1] as Label).text
	return rows


func _show(title: String, style: StringName, tint: Color) -> void:
	_title.text = title
	_title.theme_type_variation = style
	_tint_material().set_shader_parameter(&"tint", tint)
	_fill(recorder.stats if recorder else RunStats.new())
	_retry.text = tr(&"RESULTS_RETRY") % InteractionPrompt.key_text(InputActions.RETRY)
	_set_open(true)
	_retry.grab_focus()


func _fill(stats: RunStats) -> void:
	for cell: Node in _rows.get_children():
		cell.free()
	if not stats.stage_key.is_empty():
		_add_row(&"RESULTS_STAGE", tr(stats.stage_key))
	_add_row(&"RESULTS_TIME", RunClock.format(stats.seconds))
	if stats.won:
		_add_row(&"RESULTS_BOSS_BONUS", tr(&"RESULTS_BOSS_BONUS_VALUE") % StatFormat.number(stats.boss_bonus))
	_add_row(&"RESULTS_LEVEL", str(stats.level))
	_add_row(&"RESULTS_KILLS", str(stats.kills))
	_add_row(&"RESULTS_ELITE_KILLS", str(stats.elite_kills))
	_add_row(&"RESULTS_GOLD", str(floori(stats.gold_earned)))
	_add_row(&"RESULTS_DAMAGE", str(floori(stats.damage_dealt)))
	_add_row(&"RESULTS_BRO_COINS", tr(&"RESULTS_BRO_COINS_VALUE") % stats.bro_coins)
	if recorder and recorder.place >= 0:
		_add_row(&"RESULTS_RECORD_PLACE", tr(&"RESULTS_RECORD_PLACE_VALUE") % (recorder.place + 1))
	for quest: QuestData in recorder.completed_quests if recorder else []:
		_add_row(&"RESULTS_UNLOCKED", tr(quest.reward.get(&"name_key") as StringName))


func _add_row(name_key: StringName, value: String) -> void:
	var title := Label.new()
	title.theme_type_variation = &"StatNameLabel"
	title.text = String(name_key)
	_rows.add_child(title)
	var amount := Label.new()
	amount.theme_type_variation = &"StatValueLabel"
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# La columna de valores ocupa el resto del panel: los números quedan pegados a su borde.
	amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount.text = value
	_rows.add_child(amount)


func _set_open(open_panel: bool) -> void:
	visible = open_panel
	if open_panel:
		UiMotion.appear(_content)
	get_tree().paused = open_panel
	EventBus.cursor_requested.emit(self, open_panel)


## Material del fondo (el desenfoque con su color).
func _tint_material() -> ShaderMaterial:
	return _blur.material as ShaderMaterial


func _on_player_died() -> void:
	# Al final del fotograma: si morir cuenta como victoria, el aviso llega mientras tanto y manda.
	_end_with_death.call_deferred()


func _end_with_death() -> void:
	if _ended:
		return
	_ended = true
	# Temporizador del árbol que se para con la pausa: si hay otra pantalla abierta, espera.
	get_tree().create_timer(delay, false).timeout.connect(open)


func _on_run_won(victory_key: StringName, _seconds: float, _bonus: float) -> void:
	if _ended:
		return
	_ended = true
	get_tree().create_timer(victory_delay, false).timeout.connect(open_victory.bind(victory_key))


func _to_main_menu() -> void:
	RunFlow.to_main_menu(get_tree())
