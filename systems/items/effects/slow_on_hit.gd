class_name SlowOnHit
extends OnHitEffect
## Frío: el enemigo va más despacio ([member speed_factor] de su velocidad) durante
## [member duration] segundos. Volver a enfriarlo alarga el frío; no se acumula.

## Velocidad que le queda (0,6 = un 40 % más lento).
@export_range(0.05, 1.0, 0.05) var speed_factor: float = 1.0
## Segundos que dura.
@export_range(0.1, 30.0, 0.1, "suffix:s") var duration: float = 0.0


func apply(effects: OnHitEffects, target: Node3D, _health: HealthComponent, _hit: DamageInfo) -> void:
	effects.slow(target, speed_factor, duration)


func _values(copies: int) -> Array:
	return [_number(chance * copies), _number((1.0 - speed_factor) * 100.0), _number(duration)]
