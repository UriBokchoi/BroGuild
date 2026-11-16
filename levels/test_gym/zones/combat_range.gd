class_name CombatRange
extends Node3D
## Zona de práctica de combate del gimnasio: muñecos, armería, plataforma de vuelta y un recogedor
## de caídas que devuelve a la llegada ([member arrival]). Quien coloca la zona dice adónde lleva
## la vuelta ([member exit_destination]).

## Plataforma de vuelta a la zona de movimiento.
@export var exit_teleporter: Teleporter
## Adónde lleva la vuelta.
@export var exit_destination: Node3D
## Punto de llegada a esta zona.
@export var arrival: Node3D


func _ready() -> void:
	exit_teleporter.destination = exit_destination
