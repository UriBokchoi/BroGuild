class_name OffenseData
extends Resource
## Stats de ataque del personaje, que modifican a todas sus armas: daño, crítico, cadencia,
## proyectiles, área, duración y retroceso. Los porcentajes se guardan como porcentaje
## (100 = normal), así una mejora de «+10 % de daño» es un modificador PERCENT de 0.1 y
## «+5 % de crítico», uno FLAT de 5. Los valores viven en [code]data/player/offense.tres[/code];
## aquí todo vale 0 a propósito. Su efecto exacto está en el GDD (§6, «Stats del personaje»).

@export_group("offense")
## Multiplica el daño de todas las armas.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:%") var damage: float = 0.0
## Probabilidad de golpe crítico.
@export_range(0.0, 100.0, 0.5, "suffix:%") var crit_chance: float = 0.0
## Daño de un crítico respecto al normal (nunca menos del 100 %).
@export_range(100.0, 1000.0, 1.0, "or_greater", "suffix:%") var crit_damage: float = 0.0
## Cadencia de todas las armas: a más, menos tiempo entre ataques.
@export_range(10.0, 1000.0, 1.0, "or_greater", "suffix:%") var attack_speed: float = 0.0
## Proyectiles que se suman a los de cada arma.
@export_range(0, 20, 1, "or_greater") var projectile_count: int = 0
## Velocidad de los proyectiles.
@export_range(10.0, 1000.0, 1.0, "or_greater", "suffix:%") var projectile_speed: float = 0.0
## Tamaño de proyectiles y áreas.
@export_range(10.0, 1000.0, 1.0, "or_greater", "suffix:%") var area: float = 0.0
## Duración de los efectos de las armas.
@export_range(10.0, 1000.0, 1.0, "or_greater", "suffix:%") var duration: float = 0.0
## Empuje de los golpes.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:%") var knockback: float = 0.0
