class_name StatScaling
extends Resource
## Una stat de los enemigos que se multiplica con la dificultad: el [WaveDirector] aplica a cada
## enemigo que saca un multiplicador de [member stat] igual al valor de [member multiplier] con la
## dificultad de ese momento (sube 1 por minuto y más con objetos; ver [WaveData]). La stat puede
## ser del enemigo ([code]max_health[/code], [code]contact_damage[/code]…) o de sus armas
## ([code]damage[/code]). Vive dentro de un [WaveData] o de un [BossData] (el jefe lleva sus curvas).

## Nombre de la stat.
@export var stat: StringName = &""
## Multiplicador (y) según la dificultad (x).
@export var multiplier: Curve


## Multiplicador con dificultad [param difficulty] (1 si no hay curva).
func multiplier_at(difficulty: float) -> float:
	return multiplier.sample(difficulty) if multiplier else 1.0
