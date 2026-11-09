class_name PlayerInput
extends Node
## Lee el InputMap para el movimiento: convierte las pulsaciones en acciones de la máquina y
## da la dirección pedida relativa a la cámara. Solo escucha las acciones que activan algún
## estado, así que un estado nuevo con su acción funciona sin tocar este script.

@export var machine: StateMachine
## Cámara cuyo giro define el «adelante» del movimiento.
@export var camera: CameraRig


func _unhandled_input(event: InputEvent) -> void:
	for action: StringName in machine.get_trigger_actions():
		if event.is_action_pressed(action):
			machine.request(action)


## Dirección pedida en el mundo (plano XZ, longitud 0–1), relativa a hacia dónde mira la cámara.
func move_direction() -> Vector3:
	var stick := Input.get_vector(
		InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT,
		InputActions.MOVE_FORWARD, InputActions.MOVE_BACK
	)
	return Vector3(stick.x, 0.0, stick.y).rotated(Vector3.UP, camera.get_yaw())
