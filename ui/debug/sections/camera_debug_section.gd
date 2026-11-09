class_name CameraDebugSection
extends DebugSection
## Nivel de la cámara: un deslizador para probar cuánto se aleja con el nivel. Va de 1 al
## último nivel de la curva de distancia.

var _camera: CameraRig
var _level: Label


func setup(player: Player) -> void:
	_camera = player.input.camera
	add_title("camera")
	_level = add_value_row("level")
	var slider := HSlider.new()
	var curve := _camera.data.distance_by_level
	slider.min_value = 1.0
	slider.max_value = curve.max_domain if curve else 1.0
	slider.step = 1.0
	slider.value = _camera.level
	# Sin foco, para que las flechas o Espacio no lo muevan.
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(value: float) -> void: set_level(roundi(value)))
	add_child(slider)


func refresh() -> void:
	_level.text = "%d (%.2f m)" % [_camera.level, _camera.data.distance_at(_camera.level)]


## Pone la cámara en el nivel [param level].
func set_level(level: int) -> void:
	_camera.level = level
