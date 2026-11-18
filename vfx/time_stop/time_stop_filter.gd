class_name TimeStopFilter
extends CanvasLayer
## Filtro azul del tiempo parado: al pararse ([signal EventBus.time_stop_changed]) la pantalla se
## tiñe de azul en [member fade_time] segundos y, al volver a correr, se destiñe. Va por debajo del
## HUD. Solo visual.

## Segundos que tarda en teñirse o desteñirse.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_time: float = 0.25

var _fade: Tween

@onready var _filter: ColorRect = %Filter


func _enter_tree() -> void:
	if not EventBus.time_stop_changed.is_connected(_on_time_stop_changed):
		EventBus.time_stop_changed.connect(_on_time_stop_changed)


func _ready() -> void:
	_filter.visible = false
	_material().set_shader_parameter(&"strength", 0.0)


## Cuánto se tiñe ahora (0–1).
func get_strength() -> float:
	return _material().get_shader_parameter(&"strength")


func _material() -> ShaderMaterial:
	return _filter.material as ShaderMaterial


func _on_time_stop_changed(active: bool) -> void:
	if _fade:
		_fade.kill()
	_filter.visible = true
	_fade = create_tween()
	_fade.tween_property(_material(), ^"shader_parameter/strength", 1.0 if active else 0.0, fade_time)
	if not active:
		_fade.tween_callback(_filter.hide)
