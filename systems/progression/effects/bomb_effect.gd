class_name BombEffect
extends PickupEffect
## Bomba: a cada enemigo a menos de [member radius] del jugador le quita una parte de su vida máxima
## (lo que vale el recogible: 1 = toda), así que sirve igual al principio que con la dificultad
## alta.

## Enemigos que pueden recibir la explosión.
@export var swarm: EnemySwarm
## Centro de la explosión (el jugador).
@export var center: Node3D
## Alcance de la explosión.
@export_range(1.0, 100.0, 0.5, "suffix:m") var radius: float = 15.0


func apply(amount: float) -> void:
	var at := center.global_position
	for enemy: Enemy in swarm.get_active():
		if enemy.global_position.distance_to(at) <= radius:
			enemy.health.take_damage(DamageInfo.create(enemy.health.get_maximum() * amount))
