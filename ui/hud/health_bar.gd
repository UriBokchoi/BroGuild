class_name HealthBar
extends ProgressBar
## Vida del jugador en el HUD, con los números dentro de la barra («85 / 120»: la actual redondeada
## hacia arriba, para no ver un 0 estando vivo). Se entera por
## [signal EventBus.player_health_changed]. Estilo: variaciones [code]HealthBar[/code] y
## [code]HealthValueLabel[/code] del Theme global.

## Clave del texto de los números (con dos [code]%d[/code]: la vida y la máxima).
@export var value_key: StringName = &"HUD_HEALTH_VALUE"

var _current: float = 0.0
var _maximum: float = 0.0

@onready var _value: Label = %HealthValue


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.player_health_changed.is_connected(show_health):
		EventBus.player_health_changed.connect(show_health)


func _ready() -> void:
	show_percentage = false
	step = 0.0
	_show_value()


func _notification(what: int) -> void:
	# Al cambiar de idioma, el texto se vuelve a escribir.
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_show_value()


## Muestra [param current] de [param maximum].
func show_health(current: float, maximum: float) -> void:
	max_value = maximum
	value = current
	_current = current
	_maximum = maximum
	if is_node_ready():
		_show_value()


## El texto de los números que se ve ahora.
func get_value_text() -> String:
	return _value.text


func _show_value() -> void:
	_value.text = tr(value_key) % [ceili(_current), roundi(_maximum)]
