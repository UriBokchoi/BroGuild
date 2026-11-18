class_name HealShopData
extends Resource
## Cómo cura un sitio donde se paga por vida (la taberna): qué parte de la vida máxima cura y cuánto
## cuesta (sube con la dificultad y con cada vez que se usa ese sitio). Los valores viven en
## [code]data/heal_shops/[/code]; aquí todo vale 0 a propósito.

## Parte de la vida máxima que cura cada vez (0,5 = la mitad).
@export_range(0.0, 1.0, 0.05) var heal_fraction: float = 0.0
@export_group("cost")
## Oro que cuesta la primera vez con dificultad 0.
@export_range(0.0, 10000.0, 1.0, "or_greater") var base_cost: float = 0.0
## Oro que se suma por cada punto de dificultad.
@export_range(0.0, 1000.0, 0.5, "or_greater") var cost_per_difficulty: float = 0.0
## Multiplica el coste por cada vez que ya se ha usado.
@export_range(1.0, 10.0, 0.05) var cost_growth: float = 1.0


## Oro que cuesta con dificultad [param difficulty] tras [param uses] usos.
func cost_at(difficulty: float, uses: int) -> int:
	return roundi((base_cost + cost_per_difficulty * maxf(difficulty, 0.0)) * pow(cost_growth, uses))
