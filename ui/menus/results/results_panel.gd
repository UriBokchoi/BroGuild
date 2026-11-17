class_name ResultsPanel
extends CanvasLayer
## Pantalla de resultados: al morir el jugador ([code]EventBus.player_died[/code]) y pasados
## [member delay] segundos, pausa el juego, pide el cursor y muestra lo que pasó en la partida
## (según su [RunRecorder]): tiempo, nivel, enemigos y élites derrotados, oro ganado y daño
## infligido. Arriba, una frase de muerte al azar. «Reintentar» (o su tecla, [code]retry[/code])
## empieza otra partida al momento; «Salir» vuelve al menú principal ([RunFlow]). Esc no la cierra.
## Funciona con el juego en pausa ([code]process_mode = ALWAYS[/code] en la escena).

## Quién apuntó la partida.
@export var recorder: RunRecorder
## Segundos entre la muerte y los resultados (para ver caer al jugador).
@export_range(0.0, 5.0, 0.05, "suffix:s") var delay: float = 1.0
## Frases de muerte (claves de traducción): sale una al azar en cada muerte.
@export var death_lines: Array[StringName] = []

## Azar de la frase. Si no se asigna antes de entrar en el árbol, el flujo cosmético de
## [code]Rng[/code].
var rng: RandomNumberGenerator

@onready var _title: Label = %Title
@onready var _rows: GridContainer = %Rows
@onready var _retry: Button = %Retry
@onready var _quit: Button = %Quit


func _ready() -> void:
	visible = false
	if rng == null:
		rng = Rng.stream(Rng.Stream.COSMETIC)
	_retry.pressed.connect(retry)
	_quit.pressed.connect(_to_main_menu)
	EventBus.player_died.connect(_on_player_died)


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


## Muestra los resultados de la partida con una frase de muerte al azar, pausa el juego y deja el
## foco en «Reintentar».
func open() -> void:
	if not death_lines.is_empty():
		_title.text = String(death_lines[rng.randi_range(0, death_lines.size() - 1)])
	_fill(recorder.stats if recorder else RunStats.new())
	_retry.text = tr(&"RESULTS_RETRY") % InteractionPrompt.key_text(InputActions.RETRY)
	_set_open(true)
	_retry.grab_focus()


func is_open() -> bool:
	return visible


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


func _fill(stats: RunStats) -> void:
	for cell: Node in _rows.get_children():
		cell.free()
	_add_row(&"RESULTS_TIME", RunClock.format(stats.seconds))
	_add_row(&"RESULTS_LEVEL", str(stats.level))
	_add_row(&"RESULTS_KILLS", str(stats.kills))
	_add_row(&"RESULTS_ELITE_KILLS", str(stats.elite_kills))
	_add_row(&"RESULTS_GOLD", str(floori(stats.gold_earned)))
	_add_row(&"RESULTS_DAMAGE", str(floori(stats.damage_dealt)))


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
	get_tree().paused = open_panel
	EventBus.cursor_requested.emit(self, open_panel)


func _on_player_died() -> void:
	# Temporizador del árbol que se para con la pausa: si hay otra pantalla abierta, espera.
	get_tree().create_timer(delay, false).timeout.connect(open)


func _to_main_menu() -> void:
	RunFlow.to_main_menu(get_tree())
