class_name CameraData
extends Resource
## Parámetros de la cámara en tercera persona. Los valores viven en
## [code]data/player/camera.tres[/code]; aquí todo vale 0 o null a propósito, porque Godot no
## guarda en el [code].tres[/code] lo que coincide con el valor por defecto del script.

@export_group("distance")
## Distancia de la cámara al pivote a nivel 1.
@export_range(1.0, 20.0, 0.1, "or_greater", "suffix:m") var base_distance: float = 0.0
## Multiplica [member base_distance] según el nivel (eje X: nivel 1–100). Pasado el último
## punto, se queda en su valor.
@export var distance_by_level: Curve

@export_group("framing")
## Altura del punto alrededor del que orbita la cámara, medida desde los pies del objetivo.
@export_range(0.0, 3.0, 0.05, "or_greater", "suffix:m") var pivot_height: float = 0.0
## Campo de visión vertical.
@export_range(30.0, 120.0, 0.1, "suffix:°") var fov: float = 0.0
## Grados que se suman al FOV según la velocidad horizontal del objetivo (eje X: m/s).
@export var fov_by_speed: Curve
## Rapidez con la que el FOV sigue a la velocidad (más alto, más inmediato).
@export_range(0.0, 60.0, 0.5, "or_greater", "suffix:1/s") var fov_smoothing: float = 0.0

@export_group("control")
## Grados que gira la cámara por cada píxel que se mueve el ratón.
@export_range(0.01, 1.0, 0.01, "or_greater", "suffix:°/px") var mouse_sensitivity: float = 0.0
## Inclinación mínima: mirando hacia abajo, con la cámara por encima del personaje.
@export_range(-89.0, 0.0, 0.1, "radians_as_degrees") var pitch_min: float = 0.0
## Inclinación máxima: mirando hacia arriba, con la cámara por debajo.
@export_range(0.0, 89.0, 0.1, "radians_as_degrees") var pitch_max: float = 0.0
## Inclinación al empezar.
@export_range(-89.0, 89.0, 0.1, "radians_as_degrees") var initial_pitch: float = 0.0


## Distancia de la cámara al pivote para [param level].
func distance_at(level: int) -> float:
	if distance_by_level == null:
		return base_distance
	return base_distance * distance_by_level.sample(level)


## FOV para una velocidad horizontal de [param speed] m/s.
func fov_at(speed: float) -> float:
	if fov_by_speed == null:
		return fov
	return fov + fov_by_speed.sample(speed)
