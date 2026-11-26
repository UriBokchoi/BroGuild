class_name EvilEyeStats
extends ProjectileStats
## Stats del Mal de ojo (el arma del Brujo), además de las de un arma de proyectiles.

@export_group("evil_eye")
## Veces que salta a otro enemigo tras dar a uno, con todo su daño.
@export_range(0, 20, 1, "or_greater") var bounces: int = 0
## Distancia máxima a la que busca el siguiente enemigo al rebotar.
@export_range(0.5, 50.0, 0.1, "or_greater", "suffix:m") var bounce_range: float = 0.0
## Lo rápido que gira hacia su objetivo (por segundo; 0: vuela recto).
@export_range(0.0, 30.0, 0.1, "or_greater") var homing: float = 0.0
## Radio de la explosión de un crítico (lo multiplica el área).
@export_range(0.2, 20.0, 0.05, "or_greater", "suffix:m") var explosion_radius: float = 0.0
