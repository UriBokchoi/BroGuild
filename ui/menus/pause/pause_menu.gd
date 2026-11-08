class_name PauseMenu
extends CanvasLayer
## Menú de pausa (Esc): pausa el juego y pide el cursor. A la izquierda, las opciones; a la
## derecha, todas las stats del jugador. «Opciones» aún no hace nada (desactivado).
## Funciona con el juego en pausa ([code]process_mode = ALWAYS[/code] en la escena).

## Jugador cuyas stats se muestran.
@export var player: Player

@onready var _continue: Button = %Continue
@onready var _retry: Button = %Retry
@onready var _quit: Button = %Quit
@onready var _stats_view: StatsView = %StatsView


func _ready() -> void:
	_continue.pressed.connect(close)
	_retry.pressed.connect(_retry_run)
	_quit.pressed.connect(_quit_game)
	_stats_view.show_stats(player.stats)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.PAUSE):
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
