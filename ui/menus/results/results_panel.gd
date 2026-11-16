class_name ResultsPanel
extends CanvasLayer
## Pantalla de resultados: al morir el jugador ([code]EventBus.player_died[/code]) y pasados
## [member delay] segundos, pausa el juego, pide el cursor y muestra lo que pasó en la partida
## (según su [RunRecorder]): tiempo, nivel, enemigos y élites derrotados, oro ganado y daño
## infligido. «Reintentar» (o su tecla, [code]retry[/code]) empieza otra partida al momento
## recargando el nivel; «Salir» cierra el juego. Esc no la cierra. Funciona con el juego en pausa
## ([code]process_mode = ALWAYS[/code] en la escena).

## Quién apuntó la partida.
@export var recorder: RunRecorder
## Segundos entre la muerte y los resultados (para ver caer al jugador).
@export_range(0.0, 5.0, 0.05, "suffix:s") var delay: float = 1.0

@onready var _rows: GridContainer = %Rows
@onready var _retry: Button = %Retry
@onready var _quit: Button = %Quit


func _ready() -> void:
	visible = false
	_retry.pressed.connect(retry)
	_quit.pressed.connect(_quit_game)
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


## Muestra los resultados de la partida, pausa el juego y deja el foco en «Reintentar».
func open() -> void:
	_fill(recorder.stats if recorder else RunStats.new())
	_retry.text = tr(&"RESULTS_RETRY") % InteractionPrompt.key_text(InputActions.RETRY)
	_set_open(true)
	_retry.grab_focus()


func is_open() -> bool:
	return visible


## Empieza otra partida: recarga el nivel (reinicio rápido).
func retry() -> void:
	_set_open(false)
	get_tree().reload_current_scene()


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


func _quit_game() -> void:
	get_tree().quit()
