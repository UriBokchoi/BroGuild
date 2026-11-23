class_name HealthBar
extends ProgressBar
## Vida del jugador en el HUD, con los números dentro de la barra («85 / 120»: la actual redondeada
## hacia arriba, para no ver un 0 estando vivo). Se entera por
## [signal EventBus.player_health_changed]. Al perder vida, la barra baja de golpe y deja detrás un
## rastro claro ([code]HealthTrail[/code]) que se vacía con retraso: se lee cuánto quitó el golpe. Al
## curarse, sube suave ([UiMotion]). Estilo: variaciones [code]HealthBar[/code] (solo el relleno),
## [code]HealthTrailBar[/code] (fondo y rastro) y [code]HealthValueLabel[/code] del Theme global.

## Clave del texto de los números (con dos [code]%d[/code]: la vida y la máxima).
@export var value_key: StringName = &"HUD_HEALTH_VALUE"

var _current: float = 0.0
var _maximum: float = 0.0
## El primer aviso se pone tal cual (sin subir desde 0).
var _first: bool = true
var _slide: Tween
var _drain: Tween

@onready var _value: Label = %HealthValue
@onready var _trail: ProgressBar = %HealthTrail


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.player_health_changed.is_connected(show_health):
		EventBus.player_health_changed.connect(show_health)


func _ready() -> void:
	show_percentage = false
	step = 0.0
	# El primer aviso puede llegar antes (en el _ready del jugador): el rastro empieza igual.
	_trail.max_value = max_value
	_trail.value = value
	if _maximum > 0.0:
		_first = false
	_show_value()


func _notification(what: int) -> void:
	# Al cambiar de idioma, el texto se vuelve a escribir.
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_show_value()


## Muestra [param current] de [param maximum].
func show_health(current: float, maximum: float) -> void:
	var lost := current < _current and not _first
	max_value = maximum
	_current = current
	_maximum = maximum
	if not is_node_ready():
		value = current
		return
	_trail.max_value = maximum
	_stop(_slide)
	if lost:
		value = current
		_drain_trail_to(current)
	elif _first or is_equal_approx(value, current):
		value = current
		_trail.value = current
	else:
		_slide = UiMotion.slide(self, current)
		_stop(_drain)
		_trail.value = current
	_first = false
	_show_value()


## Valor del rastro de la vida perdida ahora.
func get_trail_value() -> float:
	return _trail.value


## El texto de los números que se ve ahora.
func get_value_text() -> String:
	return _value.text


func _show_value() -> void:
	_value.text = tr(value_key) % [ceili(_current), roundi(_maximum)]


## El rastro se queda donde estaba y, tras un momento, baja hasta [param current].
func _drain_trail_to(current: float) -> void:
	_stop(_drain)
	_trail.value = maxf(_trail.value, value)
	_drain = create_tween()
	_drain.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_drain.tween_interval(UiMotion.DATA.trail_delay)
	_drain.tween_property(_trail, ^"value", current, UiMotion.DATA.trail_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


static func _stop(tween: Tween) -> void:
	if tween and tween.is_valid():
		tween.kill()
