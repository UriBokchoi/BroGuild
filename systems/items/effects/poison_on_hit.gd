class_name PoisonOnHit
extends OnHitEffect
## Veneno: el enemigo pierde cada [member tick_interval] segundos una parte del golpe que lo
## envenenó ([member tick_share]) durante [member duration] segundos. Así escala con todo lo que
## sube el golpe (el daño %, el crítico, el arma). Envenenar a uno que ya lo está alarga su veneno
## y se queda con el más fuerte.

## Parte del golpe que quita cada tick (0,1 = un 10 %).
@export_range(0.0, 5.0, 0.01) var tick_share: float = 0.0
## Segundos entre ticks.
@export_range(0.05, 5.0, 0.05, "suffix:s") var tick_interval: float = 0.5
## Segundos que dura.
@export_range(0.1, 30.0, 0.1, "suffix:s") var duration: float = 0.0


func apply(effects: OnHitEffects, target: Node3D, health: HealthComponent, hit: DamageInfo) -> void:
	effects.poison(target, health, hit.amount * tick_share, tick_interval, duration, kind)


## Parte del golpe que quita en total.
func total_share() -> float:
	return tick_share * ticks_in(duration, tick_interval)


## Ticks que caben en [param seconds] con uno cada [param interval] segundos.
static func ticks_in(seconds: float, interval: float) -> int:
	return maxi(roundi(seconds / interval), 1)


func _values(copies: int) -> Array:
	return [_number(chance * copies), _number(total_share() * 100.0), _number(duration)]
