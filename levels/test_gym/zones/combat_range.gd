class_name CombatRange
extends Node3D
## Zona de práctica de combate del gimnasio: muñecos, armería, invocador de enemigos, plataforma
## de vuelta y un recogedor de caídas que devuelve a la llegada ([member arrival]). Quien coloca la
## zona dice adónde lleva la vuelta ([member exit_destination]) y dónde viven los enemigos
## ([member swarm]).

## Plataforma de vuelta a la zona de movimiento.
@export var exit_teleporter: Teleporter
## Adónde lleva la vuelta.
@export var exit_destination: Node3D
## Punto de llegada a esta zona.
@export var arrival: Node3D
## Invocador de enemigos de práctica.
@export var summoner: Summoner
## Enemigos del nivel, donde salen los invocados.
@export var swarm: EnemySwarm


func _ready() -> void:
	exit_teleporter.destination = exit_destination
	summoner.swarm = swarm
