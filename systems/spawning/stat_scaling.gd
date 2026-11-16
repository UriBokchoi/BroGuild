class_name StatScaling
extends Resource
## Una stat de los enemigos que se multiplica con el tiempo de partida (la dificultad): el
## [WaveDirector] aplica a cada enemigo que saca un multiplicador de [member stat] igual al valor
## de [member multiplier] en ese minuto. La stat puede ser del enemigo ([code]max_health[/code],
## [code]contact_damage[/code]…) o de sus armas ([code]damage[/code]). Vive dentro de un [WaveData].

## Nombre de la stat.
@export var stat: StringName = &""
## Multiplicador (y) según los minutos de partida (x).
@export var multiplier: Curve


## Multiplicador a los [param seconds] de partida (1 si no hay curva).
func multiplier_at(seconds: float) -> float:
	return multiplier.sample(seconds / 60.0) if multiplier else 1.0
