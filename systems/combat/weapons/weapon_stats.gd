class_name WeaponStats
extends Resource
## Stats propias de un arma, antes de las del personaje ([OffenseData]): cada número es una stat, así
## que sus mejoras de nivel son modificadores ([StatModifierSet] en [WeaponData]). El arma combina
## las dos en [Weapon]: el daño % y el crítico del personaje van en el golpe, su velocidad de
## ataque divide [member cooldown], sus proyectiles se suman a [member projectiles] y su área y
## duración multiplican las del arma. Los valores viven en el [code].tres[/code] de cada arma; aquí
## todo vale 0 a propósito. Un arma con stats que no tienen las demás extiende este Resource.

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
