class_name MovementContext
extends RefCounted
## Lo que comparten los estados de movimiento del jugador. Lo monta [Player] al arrancar; los
## sensores, contadores y temporizadores de cada mecánica se añaden aquí cuando llegan.

## Cuerpo que se mueve. Solo [Player] llama a [method CharacterBody3D.move_and_slide].
var body: CharacterBody3D
## Stats de movimiento con los modificadores aplicados (copia resuelta de movement.tres).
var move: MovementData
## Estado neutro en el suelo, al que vuelven las acciones al terminar.
var ground: State
## Estado neutro en el aire, al que vuelven las acciones al terminar.
var air: State
## Dirección pedida este tick, en el plano XZ del mundo y relativa a la cámara (longitud 0–1).
var wish_direction: Vector3 = Vector3.ZERO
## Segundos que quedan para poder saltar después de dejar el suelo sin saltar (coyote time).
var coyote_left: float = 0.0
