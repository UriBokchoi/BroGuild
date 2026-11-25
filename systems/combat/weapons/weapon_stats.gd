class_name WeaponStats
extends Resource
## Las stats propias de un arma. Se combinan con las del personaje: su daño % y su crítico van en el
## golpe, su velocidad de ataque acorta la espera, sus proyectiles se suman y su área y duración
## multiplican. Los valores viven en el .tres de cada arma; un arma con stats propias extiende esto.

@export_group("weapon")
## Daño de cada golpe.
@export_range(0.0, 10000.0, 0.5, "or_greater") var damage: float = 0.0
## Segundos entre ataques.
@export_range(0.05, 60.0, 0.01, "or_greater", "suffix:s") var cooldown: float = 0.0
## Golpes de cada ataque (tajos, proyectiles…).
@export_range(1, 20, 1, "or_greater") var projectiles: int = 0
## Segundos entre los golpes de un mismo ataque.
@export_range(0.0, 2.0, 0.01, "or_greater", "suffix:s") var burst_interval: float = 0.0
## Tamaño de los golpes.
@export_range(10.0, 1000.0, 1.0, "or_greater", "suffix:%") var area: float = 0.0
## Segundos que dura cada golpe.
@export_range(0.05, 30.0, 0.01, "or_greater", "suffix:s") var duration: float = 0.0
## Distancia hasta la que busca objetivos.
@export_range(0.5, 100.0, 0.1, "or_greater", "suffix:m") var reach: float = 0.0
## Empuje de cada golpe (lo multiplica el empuje % de quien la lleva).
@export_range(0.0, 50.0, 0.5, "or_greater", "suffix:m/s") var knockback: float = 0.0
