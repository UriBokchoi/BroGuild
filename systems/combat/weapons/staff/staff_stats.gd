class_name StaffStats
extends ProjectileStats
## Stats del bastón de mago, además de las de un arma de proyectiles.

@export_group("staff")
## Radio de la explosión (lo multiplica el área).
@export_range(0.2, 20.0, 0.05, "or_greater", "suffix:m") var explosion_radius: float = 0.0
