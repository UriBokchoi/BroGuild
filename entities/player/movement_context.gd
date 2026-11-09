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
## Segundos que quedan para poder saltar después de dejar el suelo sin saltar (coyote time).
var coyote_left: float = 0.0
## Saltos en el aire gastados desde que se dejó el suelo.
var air_jumps_used: int = 0
## Momento ([member elapsed]) del último dash, para el picado.
var last_dash_time: float = -INF
## Si el último dash empezó en el aire.
var last_dash_in_air: bool = false
