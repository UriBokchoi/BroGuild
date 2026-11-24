class_name CombatRange
extends Node3D
## La zona de combate del gimnasio de pruebas: muñecos, armería, invocadores de enemigos, la campana
## de las oleadas y un recogedor de caídas. Quien la coloca dice adónde lleva la vuelta, dónde viven
## los enemigos y qué director usa la campana. Al volver a la zona de movimiento, las oleadas paran.

## Plataforma de vuelta a la zona de movimiento.
@export var exit_teleporter: Teleporter
## Adónde lleva la vuelta.
@export var exit_destination: Node3D
## Punto de llegada a esta zona.
@export var arrival: Node3D
## Invocadores de enemigos de práctica (uno por tipo).
@export var summoners: Array[Summoner] = []
## Campana que empieza y para las oleadas.
@export var wave_bell: WaveBell
## Enemigos del nivel, donde salen los invocados.
@export var swarm: EnemySwarm
## Director de oleadas del nivel.
@export var director: WaveDirector


func _ready() -> void:
	exit_teleporter.destination = exit_destination
	exit_teleporter.teleported.connect(_on_player_left)
	for summoner: Summoner in summoners:
		summoner.swarm = swarm
	if director:
		wave_bell.use_director(director)


func _on_player_left(_player: Player) -> void:
	if director and director.is_running():
		director.stop()
