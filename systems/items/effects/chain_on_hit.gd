class_name ChainOnHit
extends OnHitEffect
## Rayo: salta del enemigo golpeado a los [member jumps] más cercanos que estén a menos de
## [member reach] metros (de uno al siguiente) y les quita una parte del golpe ([member damage_share]).

## A cuántos enemigos más salta.
@export_range(1, 20, 1) var jumps: int = 1
## Distancia máxima de cada salto.
@export_range(0.5, 30.0, 0.5, "suffix:m") var reach: float = 0.0
## Parte del golpe que quita a cada uno (0,5 = la mitad).
@export_range(0.0, 5.0, 0.01) var damage_share: float = 0.0


func apply(effects: OnHitEffects, target: Node3D, health: HealthComponent, hit: DamageInfo) -> void:
	effects.chain(target, health, hit.amount * damage_share, jumps, reach, kind)


func _values(copies: int) -> Array:
	return [_number(chance * copies), str(jumps), _number(damage_share * 100.0)]
