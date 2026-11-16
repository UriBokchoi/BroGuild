class_name MovementContext
extends RefCounted
## Lo que comparten los estados de movimiento del jugador. Lo monta [Player] al arrancar; los
## sensores, contadores y temporizadores de cada mecánica se añaden aquí cuando llegan.

## Cuerpo que se mueve. Solo [Player] llama a [method CharacterBody3D.move_and_slide].
var body: CharacterBody3D
## Stats de movimiento con los modificadores aplicados (copia resuelta de movement.tres).
var move: MovementData
## Stamina por cargas que gastan las acciones.
var stamina: StaminaComponent
## Estado neutro en el suelo, al que vuelven las acciones al terminar.
var ground: State
## Estado neutro en el aire, al que vuelven las acciones al terminar.
var air: State
## Segundos de juego desde que empezó el movimiento (para medir ventanas entre acciones).
var elapsed: float = 0.0
## Dirección pedida este tick, en el plano XZ del mundo y relativa a la cámara (longitud 0–1).
var wish_direction: Vector3 = Vector3.ZERO
## Hacia dónde mira la cámara en el plano XZ (longitud 1): la dirección por defecto del dash.
var view_forward: Vector3 = Vector3.FORWARD
## Si se mantiene pulsada la acción de slide (Ctrl) este tick.
var slide_held: bool = false
## Segundos seguidos pidiendo dirección (lleva al sprint).
var sprint_time: float = 0.0
## Segundos que quedan para poder saltar después de dejar el suelo sin saltar (coyote time).
var coyote_left: float = 0.0
## Saltos en el aire gastados desde que se dejó el suelo.
var air_jumps_used: int = 0
## Dashes empezados en el aire desde que se dejó el suelo.
var air_dashes_used: int = 0
## Si el último dash empezó en el aire.
var last_dash_in_air: bool = false
## Dirección del último dash (la que recupera el dash-jump).
var last_dash_direction: Vector3 = Vector3.FORWARD
## Momento ([member elapsed]) en que acabó el último dash; abre la ventana del dash-jump.
var dash_end_time: float = -INF
## Saltos en pared encadenados desde que se dejó el suelo (el primero es gratis).
var wall_jumps_chained: int = 0
## Sensor de paredes cercanas (para el salto en pared). Sin sensor, nunca hay pared.
var wall_sensor: WallSensor
## Sensor de bordes a los que subir (para el mantle). Sin sensor, nunca hay borde.
var ledge_sensor: LedgeSensor

## Momento ([member elapsed]) de la última pulsación de cada acción y de la anterior (dobles
## pulsaciones).
var _last_press: Dictionary[StringName, float] = {}
var _previous_press: Dictionary[StringName, float] = {}


## ¿Lleva el tiempo suficiente moviéndose para ir en sprint?
func is_sprinting() -> bool:
	return sprint_time >= move.sprint_delay


## Velocidad objetivo en el suelo: la de sprint o la normal.
func ground_speed() -> float:
	return move.sprint_speed if is_sprinting() else move.run_speed


## Apunta que se acaba de pulsar [param action] (para detectar dobles pulsaciones).
func record_press(action: StringName) -> void:
	_previous_press[action] = _last_press.get(action, -INF)
	_last_press[action] = elapsed


## ¿Las dos últimas pulsaciones de [param action] están a menos de [param window] segundos?
func is_double_tap(action: StringName, window: float) -> bool:
	var last: float = _last_press.get(action, -INF)
	var previous: float = _previous_press.get(action, -INF)
	return last - previous <= window


## ¿Está abierta la ventana del dash-jump (justo después de un dash hecho en el suelo)?
func is_dash_jump_open() -> bool:
	return not last_dash_in_air and elapsed - dash_end_time <= move.dash_jump_window


## Normal de la pared más cercana al alcance del salto en pared; cero si no hay ninguna.
func wall_normal() -> Vector3:
	if wall_sensor == null:
		return Vector3.ZERO
	return wall_sensor.find_wall(move.wall_jump_reach)


## Borde al que subir hacia [param direction] con el alcance y las alturas del mantle; null si no hay.
func find_ledge(direction: Vector3) -> LedgeSensor.Ledge:
	if ledge_sensor == null:
		return null
	return ledge_sensor.find_ledge(
		direction, move.mantle_reach, move.mantle_min_height, move.mantle_max_height
	)
