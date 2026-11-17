class_name DaggerStats
extends ProjectileStats
## Stats de la daga, además de las de un arma de proyectiles.

@export_group("dagger")
## Veces que salta a otro enemigo tras dar a uno, con todo su daño.
@export_range(0, 20, 1, "or_greater") var bounces: int = 0
## Distancia máxima a la que busca el siguiente enemigo al rebotar.
@export_range(0.5, 50.0, 0.1, "or_greater", "suffix:m") var bounce_range: float = 0.0
