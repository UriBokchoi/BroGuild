class_name ModalPanel
extends CanvasLayer
## Base de los paneles que se abren encima de la partida y obligan a elegir (subir de nivel, un
## objeto): mientras están abiertos el juego está en pausa, piden el cursor y Esc no los salta (ni abre
## la pausa debajo, que al cerrarse reanudaría el juego bajo las cartas).


func _ready() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if visible:
		_set_open(false)


func close() -> void:
	if visible:
		_set_open(false)


func is_open() -> bool:
	return visible


func _set_open(open_panel: bool) -> void:
	visible = open_panel
	get_tree().paused = open_panel
	EventBus.cursor_requested.emit(self, open_panel)
