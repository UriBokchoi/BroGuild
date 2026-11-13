class_name DamageNumber
extends Label3D
## Un número de daño: salta en arco desde donde se lanza, hace «pop» y se desvanece (ver
## [DamageNumberStyle]). Se reutiliza (pool): al acabar se oculta y avisa con [signal finished].

signal finished

var _style: DamageNumberStyle
var _velocity: Vector3 = Vector3.ZERO
var _age: float = 0.0
var _size: float = 1.0
var _color: Color = Color.WHITE


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fixed_size = true
	no_depth_test = true
	shaded = false
	double_sided = true
	render_priority = 10
	outline_render_priority = 9
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Se mueve en _process: sin interpolación de física, como las cámaras.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_hide()


func _process(delta: float) -> void:
	_age += delta
	if _age >= _style.lifetime:
		_hide()
		finished.emit()
		return
	_velocity.y -= _style.gravity * delta
	global_position += _velocity * delta
	_animate()


## Muestra [param amount] en [param at]: en el color de crítico si [param critical].
## [param rng] decide la dirección del salto (azar cosmético).
func launch(
	at: Vector3,
	amount: float,
	critical: bool,
	style: DamageNumberStyle,
	rng: RandomNumberGenerator,
) -> void:
	_style = style
	text = str(maxi(roundi(amount), 1))
	font = style.font
	font_size = style.font_size
	outline_size = style.outline_size
	pixel_size = style.pixel_size
	_color = style.critical_color if critical else style.normal_color
	_size = style.critical_scale if critical else 1.0
	var side := Vector3.RIGHT.rotated(Vector3.UP, rng.randf() * TAU)
	var jitter := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(0.0, 1.0), rng.randf_range(-1.0, 1.0))
	global_position = at + jitter * style.spawn_jitter
	_velocity = side * rng.randf_range(0.3, 1.0) * style.spread_speed + Vector3.UP * style.launch_speed
	_age = 0.0
	_animate()
	visible = true
	set_process(true)


## ¿Está en pantalla?
func is_showing() -> bool:
	return visible


func _animate() -> void:
	var pop := clampf(_age / _style.pop_time, 0.0, 1.0)
	scale = Vector3.ONE * _size * lerpf(_style.pop_scale, 1.0, _ease_out_back(pop))
	var fade := 1.0 - smoothstep(_style.fade_start, 1.0, _age / _style.lifetime)
	modulate = Color(_color, _color.a * fade)
	outline_modulate = Color(_style.outline_color, _style.outline_color.a * fade)


func _hide() -> void:
	visible = false
	set_process(false)


## Llega a 1 pasándose un poco y volviendo (el rebote del «pop»).
static func _ease_out_back(t: float) -> float:
	const OVERSHOOT := 1.70158
	var u := t - 1.0
	return 1.0 + (OVERSHOOT + 1.0) * u * u * u + OVERSHOOT * u * u
