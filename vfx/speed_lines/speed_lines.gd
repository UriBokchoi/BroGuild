class_name SpeedLines
extends CanvasLayer
## Líneas de velocidad en los bordes de la pantalla: aparecen a partir de [member start_speed] y
## están a tope en [member full_speed] (velocidad horizontal de [member body]). Solo visual.

## Por debajo de esta intensidad no se dibujan (ahorra el shader a pantalla completa).
const VISIBLE_THRESHOLD := 0.01

@export var body: CharacterBody3D
## Velocidad horizontal a la que empiezan a verse.
@export_range(0.0, 100.0, 0.5, "suffix:m/s") var start_speed: float = 15.0
## Velocidad horizontal a la que están a tope.
@export_range(0.0, 100.0, 0.5, "suffix:m/s") var full_speed: float = 28.0
## Rapidez con la que siguen a la velocidad.
@export_range(0.0, 60.0, 0.5, "suffix:1/s") var smoothing: float = 10.0

var _intensity: float = 0.0

@onready var _overlay: ColorRect = %Overlay


func _ready() -> void:
	_overlay.visible = false


func _process(delta: float) -> void:
	var speed := Vector2(body.velocity.x, body.velocity.z).length()
	var target := intensity_for(speed, start_speed, full_speed)
	_intensity = lerpf(_intensity, target, 1.0 - exp(-smoothing * delta))
	_overlay.visible = _intensity > VISIBLE_THRESHOLD
	(_overlay.material as ShaderMaterial).set_shader_parameter(&"intensity", _intensity)


## Intensidad (0–1) de las líneas para [param speed]: 0 hasta [param start], 1 desde [param full].
static func intensity_for(speed: float, start: float, full: float) -> float:
	if full <= start:
		return 1.0 if speed >= full else 0.0
	return clampf(inverse_lerp(start, full, speed), 0.0, 1.0)
