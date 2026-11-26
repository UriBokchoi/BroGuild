class_name StageData
extends Resource
## Una fase de la partida en un nivel con tiers: un tier o la arena del jefe final. Tiene su mapa,
## su nombre y la dificultad que suma mientras dura. Viven en data/levels/<nivel>/.

## Nombre (clave de traducción, p. ej. «Tier 2 · Otoño»): sale al entrar y al elegir nivel.
@export var name_key: StringName = &""
## Cómo se gana si se elige este tier (clave de traducción, para la selección de nivel).
@export var goal_key: StringName = &""
## El mapa: una escena con raíz [LevelMap].
@export var map: PackedScene
## Dificultad que suma mientras se juega, además de la que sube con el tiempo.
@export_range(0.0, 100.0, 0.5, "or_greater") var difficulty: float = 0.0
## Cuánto más fuertes son los enemigos de la fase: multiplica su vida, su daño y lo que sueltan
## (1,2 = un 20 % más; ver [member WaveDirector.strength_stats]). Sale al elegir el tier.
@export_range(1.0, 5.0, 0.05, "or_greater") var strength: float = 1.0


## Lo que [member strength] sube a los enemigos, en % (1,2 → 20).
func strength_percent() -> int:
	return roundi((strength - 1.0) * 100.0)
