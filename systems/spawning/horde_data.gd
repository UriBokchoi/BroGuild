class_name HordeData
extends Resource
## Una horda: en un minuto de la ronda salen de golpe muchos enemigos alrededor del jugador, con
## aviso unos segundos antes (texto en el HUD y un cuerno). Salen repartidos en
## [member spawn_seconds] (llegan como una ola y sin un tirón por sacarlos todos en el mismo
## fotograma), con el escalado de la dificultad y sin contar para el máximo a la vez. Va en
## [member WaveData.hordes].

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
