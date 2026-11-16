class_name Pickup
extends Node3D
## Un recogible en el mundo (gema de experiencia…): su tipo, lo que vale y si ya vuela hacia quien
## lo recoge. No se mueve solo: un [PickupField] lo saca de su pool, lo mueve y lo recoge. El giro
## y el balanceo van en su shader, para que cientos de ellos no cuesten un [code]_process[/code]
## cada uno.

## Altura sobre el suelo a la que flota.
@export_range(0.0, 2.0, 0.05, "suffix:m") var float_height: float = 0.35

## Tipo de recogible (lo pone el [PickupField] al crearlo).
var data: PickupData
## Lo que vale (experiencia, fichas…).
var amount: float = 0.0
## Ya vuela hacia quien lo recoge (no se suelta aunque se aleje).
var attracted: bool = false
## Velocidad actual del vuelo.
var speed: float = 0.0


## Lo pone en el mundo sobre [param ground] con el valor [param value].
func activate(ground: Vector3, value: float) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	global_position = ground + Vector3.UP * float_height
	amount = value
	attracted = false
	speed = 0.0
	reset_physics_interpolation()


## Lo saca del mundo hasta el siguiente [method activate].
func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
