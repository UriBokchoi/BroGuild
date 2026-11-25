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
