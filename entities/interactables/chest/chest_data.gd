class_name ChestData
extends Resource
## Cómo es un cofre (GDD §5.2): de dónde sale lo que da ([ItemPool]: rarezas con la Suerte del
## jugador y carpeta de objetos), cuánto cuesta (sube con la dificultad y con cada cofre abierto en
## la partida) y cuánto dura el revelado. Los valores viven en [code]data/chests/[/code]; aquí todo
## vale 0 o vacío a propósito.

## Qué puede salir.
@export var items: ItemPool
@export_group("cost")
## Oro que cuesta el primer cofre con dificultad 0.
@export_range(0.0, 10000.0, 1.0, "or_greater") var base_cost: float = 0.0
## Oro que se suma por cada punto de dificultad.
@export_range(0.0, 1000.0, 0.5, "or_greater") var cost_per_difficulty: float = 0.0
## Multiplica el coste por cada cofre ya abierto en la partida.
@export_range(1.0, 10.0, 0.05) var cost_growth: float = 1.0
@export_group("reveal")
## Segundos que tarda en revelarse lo que sale (y en llegar al jugador).
@export_range(0.1, 10.0, 0.05, "suffix:s") var reveal_time: float = 0.0


## Oro que cuesta con dificultad [param difficulty] tras abrir [param opened] cofres en la partida.
func cost_at(difficulty: float, opened: int) -> int:
	return roundi((base_cost + cost_per_difficulty * maxf(difficulty, 0.0)) * pow(cost_growth, opened))
