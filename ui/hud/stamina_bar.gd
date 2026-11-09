class_name StaminaBar
extends HBoxContainer
## Cargas de stamina del jugador: una barra por carga, la que se está recargando a medias. Se
## entera por [signal EventBus.player_stamina_changed]; si cambia el máximo (una mejora), se
## rehace. Estilo: variación [code]ChargeBar[/code] del Theme global.

## Tamaño de cada barra.
@export var bar_size: Vector2 = Vector2(56.0, 14.0)

var _bars: Array[ProgressBar] = []


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.player_stamina_changed.is_connected(show_stamina):
		EventBus.player_stamina_changed.connect(show_stamina)


## Muestra [param charges] de [param max_charges] (las cargas pueden ser fraccionarias).
func show_stamina(charges: float, max_charges: int) -> void:
	if _bars.size() != max_charges:
		_rebuild(max_charges)
	for i: int in _bars.size():
		_bars[i].value = clampf(charges - i, 0.0, 1.0)


## Relleno de cada barra (0–1), de izquierda a derecha.
func get_fills() -> PackedFloat64Array:
	var fills := PackedFloat64Array()
	for bar: ProgressBar in _bars:
		fills.append(bar.value)
	return fills


func _rebuild(max_charges: int) -> void:
	for bar: ProgressBar in _bars:
		bar.queue_free()
	_bars.clear()
	for i: int in max_charges:
		var bar := ProgressBar.new()
		bar.theme_type_variation = &"ChargeBar"
		bar.custom_minimum_size = bar_size
		bar.max_value = 1.0
		bar.step = 0.0
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		_bars.append(bar)
