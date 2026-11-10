class_name PlayerInput
extends Node
## Lee el InputMap para el movimiento: convierte las pulsaciones en acciones de la máquina y
## da la dirección pedida relativa a la cámara. Solo escucha las acciones que activan algún
## estado, así que un estado nuevo con su acción funciona sin tocar este script.

## Se pulsó [param action] (antes de pedírsela a la máquina; sirve para dobles pulsaciones).
signal action_pressed(action: StringName)

@export var machine: StateMachine
## Cámara cuyo giro define el «adelante» del movimiento.
@export var camera: CameraRig


func _unhandled_input(event: InputEvent) -> void:
	for action: StringName in machine.get_trigger_actions():
		if event.is_action_pressed(action):
			action_pressed.emit(action)
			machine.request(action)


## Dirección pedida en el mundo (plano XZ, longitud 0–1), relativa a hacia dónde mira la cámara.
func move_direction() -> Vector3:
	var stick := Input.get_vector(
		InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT,
		InputActions.MOVE_FORWARD, InputActions.MOVE_BACK
	)
	return Vector3(stick.x, 0.0, stick.y).rotated(Vector3.UP, camera.get_yaw())


## Si [param action] está pulsada ahora mismo (para acciones que se mantienen, como el slide).
func is_held(action: StringName) -> bool:
	return Input.is_action_pressed(action)


## Hacia dónde mira la cámara en el plano XZ del mundo (longitud 1).
func view_forward() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, camera.get_yaw())
