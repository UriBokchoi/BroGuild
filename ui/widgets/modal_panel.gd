class_name ModalPanel
extends CanvasLayer
## Base de los paneles que se abren encima de la partida y obligan a elegir (subir de nivel, un
## objeto): mientras están abiertos el juego está en pausa, piden el cursor y Esc no los salta (ni abre
## la pausa debajo, que al cerrarse reanudaría el juego bajo las cartas). Al abrirse, su contenido
## ([member appear_root]) aparece con [method UiMotion.appear]. Mientras están abiertos se pueden ver
## tus stats manteniendo «ver stats» ([StatsOverlay]), y [member stats_hint] lo recuerda.

## Lo que aparece al abrirse (vacío: nada se anima).
@export var appear_root: Control
## Texto que recuerda cómo ver tus stats (vacío: ninguno).
@export var stats_hint: Label


func _ready() -> void:
	visible = false
	add_to_group(StatsOverlay.ALLOW_GROUP)
	if stats_hint:
		stats_hint.text = tr(&"HUD_STATS_HINT") % InteractionPrompt.key_text(InputActions.SHOW_STATS)


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
	if open_panel and appear_root:
		UiMotion.appear(appear_root)
	get_tree().paused = open_panel
	EventBus.cursor_requested.emit(self, open_panel)
