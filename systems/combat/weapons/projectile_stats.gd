class_name ProjectileStats
extends WeaponStats
## Stats de un arma que dispara proyectiles, además de las de toda arma. Su vida es la duración del
## arma ([member WeaponStats.duration]). Los valores viven en el [code].tres[/code] de cada arma.

@export_group("projectile")
## Velocidad del proyectil (la multiplica la velocidad de proyectil del personaje).
@export_range(1.0, 200.0, 0.5, "or_greater", "suffix:m/s") var projectile_speed: float = 0.0
