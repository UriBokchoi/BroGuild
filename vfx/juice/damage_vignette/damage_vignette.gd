class_name DamageVignette
extends CanvasLayer
## Borde rojo de la pantalla según la vida del jugador ([signal EventBus.player_health_changed]):
## un destello al perder vida que se apaga en [member flash_time] y, por debajo de
## [member low_health], un rojo que late como un corazón, más fuerte y más rápido cuanta menos vida
## queda. Va por debajo del HUD. Solo visual.

## Parte de la vida por debajo de la cual el borde se queda rojo.
@export_range(0.0, 1.0, 0.01) var low_health: float = 0.0
## Fuerza del rojo justo por debajo de [member low_health] y con la vida a cero.
@export var low_strength: Vector2 = Vector2.ZERO
## Cuánto baja la fuerza entre latido y latido (parte de la fuerza).
@export_range(0.0, 1.0, 0.01) var pulse_depth: float = 0.0
## Latidos por segundo justo por debajo de [member low_health] y con la vida a cero.
@export var pulse_rate: Vector2 = Vector2.ONE
## Fuerza del destello al perder vida.
@export_range(0.0, 1.0, 0.01) var flash_strength: float = 0.0
## Segundos que tarda en apagarse el destello.
@export_range(0.05, 2.0, 0.05, "suffix:s") var flash_time: float = 0.1

var _fraction: float = 1.0
var _last: float = -1.0
var _flash: float = 0.0
var _phase: float = 0.0

@onready var _border: ColorRect = %Border


func _enter_tree() -> void:
	if not EventBus.player_health_changed.is_connected(_on_health_changed):
		EventBus.player_health_changed.connect(_on_health_changed)


func _ready() -> void:
	# La vida puede haber llegado antes (el jugador la avisa en su _ready): se pinta ya.
	_show(0.0)
	set_process(_flash > 0.0 or _fraction < low_health)


## Lo rojo que está el borde ahora (0–1).
func get_strength() -> float:
	return _material().get_shader_parameter(&"strength")


## Cuánto falta para la vida a cero desde [member low_health] (0 = por encima, 1 = sin vida).
func danger() -> float:
	if low_health <= 0.0 or _fraction >= low_health:
		return 0.0
	return 1.0 - _fraction / low_health


func _process(delta: float) -> void:
	_flash = maxf(_flash - flash_strength / flash_time * delta, 0.0)
	var low := 0.0
	if _fraction < low_health:
		var t := danger()
		_phase = fmod(_phase + delta * lerpf(pulse_rate.x, pulse_rate.y, t), 1.0)
		var beat := 0.5 + 0.5 * cos(_phase * TAU)
		low = lerpf(low_strength.x, low_strength.y, t) * (1.0 - pulse_depth * (1.0 - beat))
	_show(maxf(low, _flash))
	if _flash <= 0.0 and _fraction >= low_health:
		set_process(false)


func _show(strength: float) -> void:
	_material().set_shader_parameter(&"strength", strength)
	_border.visible = strength > 0.0


func _material() -> ShaderMaterial:
	return _border.material as ShaderMaterial


func _on_health_changed(current: float, maximum: float) -> void:
	if maximum <= 0.0:
		return
	if _last >= 0.0 and current < _last:
		_flash = flash_strength
	_last = current
	_fraction = current / maximum
	if is_node_ready():
		set_process(true)
		_process(0.0)
