class_name MouseCapture
extends Node
## Captura el ratón para mirar con la cámara: Esc ([constant InputActions.PAUSE]) lo suelta y
## un clic en la ventana lo vuelve a capturar. Va en la escena principal, no en el jugador:
## el modo del ratón es de toda la partida. Provisional hasta que exista el menú de pausa,
## que se quedará con Esc.


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.PAUSE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
		return
	var click := event as InputEventMouseButton
	if click and click.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
