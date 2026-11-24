class_name HordeData
extends Resource
## Una horda: a su minuto salen de golpe muchos enemigos alrededor del jugador, avisados unos
## segundos antes. Salen repartidos en unos segundos, como una ola (y sin el tirón de sacarlos todos
## a la vez), y no cuentan para el máximo.

## Minuto de la ronda en que sale.
@export_range(0.0, 120.0, 0.25, "or_greater", "suffix:min") var at_minute: float = 0.0
## Enemigos que salen (de los de la oleada, según la dificultad).
@export_range(1, 500, 1, "or_greater") var count: int = 0
## De ellos, cuántos salen élites.
@export_range(0, 100, 1, "or_greater") var elites: int = 0
## Segundos que tarda en salir entera.
@export_range(0.0, 10.0, 0.1, "suffix:s") var spawn_seconds: float = 0.0
## Segundos de aviso antes de salir.
@export_range(0.0, 30.0, 0.5, "suffix:s") var warning_seconds: float = 0.0
## Texto del aviso (clave) y su color.
@export var announce_key: StringName = &""
@export var announce_color: Color = Color.WHITE


## Segundo de la ronda en que sale.
func at_seconds() -> float:
	return at_minute * 60.0
