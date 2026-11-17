class_name WaveEnemy
extends Resource
## Un enemigo que puede salir en las oleadas: cuánto sale respecto a los demás y desde qué
## dificultad.

@export var enemy: EnemyData
## Peso frente a los demás enemigos disponibles (el doble de peso, el doble de veces).
@export_range(0.0, 1000.0, 0.1, "or_greater") var weight: float = 0.0
## Dificultad a partir de la que puede salir (sube 1 por minuto; ver [WaveData]).
@export_range(0.0, 60.0, 0.1, "or_greater") var from_difficulty: float = 0.0
