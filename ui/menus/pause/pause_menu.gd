class_name PauseMenu
extends CanvasLayer
## Menú de pausa (Esc): pausa el juego y pide el cursor. A la izquierda, el menú; a la derecha,
## todas las stats del jugador. «Opciones» cambia ambos por el panel de opciones ([OptionsPanel]),
## que se cierra con Esc o «Volver».
## Funciona con el juego en pausa ([code]process_mode = ALWAYS[/code] en la escena).

## Jugador cuyas stats se muestran.
@export var player: Player

@onready var _continue: Button = %Continue
@onready var _options_button: Button = %Options
@onready var _retry: Button = %Retry
@onready var _quit: Button = %Quit
@onready var _stats_view: StatsView = %StatsView
@onready var _layout: Control = %Layout
@onready var _options: OptionsPanel = %OptionsPanel


func _ready() -> void:
	_continue.pressed.connect(close)
	_retry.pressed.connect(_retry_run)
	_quit.pressed.connect(_quit_game)
	_options_button.pressed.connect(_open_options)
	_options.closed.connect(_on_options_closed)
	_stats_view.show_stats(player.stats)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	# Con las opciones abiertas, Esc es suyo: vuelve a este menú.
	if not event.is_action_pressed(InputActions.PAUSE) or _options.visible:
		return
	if visible:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	# Si la escena se va con el menú abierto, que no deje el juego en pausa ni el cursor pedido.
	if visible:
		_set_open(false)


## Abre el menú: pausa el juego, muestra las stats al día y deja el foco en «Continuar».
func open() -> void:
	_stats_view.refresh()
	_set_open(true)
	_continue.grab_focus()


## Cierra el menú y reanuda el juego.
func close() -> void:
	_options.close()
	_layout.visible = true
	# Sin esto, un botón con foco seguiría respondiendo a Espacio (que es saltar).
	get_viewport().gui_release_focus()
	_set_open(false)


func _set_open(open_menu: bool) -> void:
	visible = open_menu
	get_tree().paused = open_menu
	EventBus.cursor_requested.emit(self, open_menu)


func _retry_run() -> void:
	close()
	get_tree().reload_current_scene()


func _quit_game() -> void:
	get_tree().quit()


func _open_options() -> void:
	_layout.visible = false
	_options.open()


func _on_options_closed() -> void:
	_layout.visible = true
	_options_button.grab_focus()
