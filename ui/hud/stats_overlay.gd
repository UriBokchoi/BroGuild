class_name StatsOverlay
extends CanvasLayer
## Las estadísticas del jugador mientras se mantiene «ver stats» (Tab), sin pausar: la misma lista
## que la pausa ([StatsView]), a la derecha y encima de la partida. Mientras se ve, se actualiza cada
## [member refresh_interval], y la rueda del ratón la desplaza. Con el juego en pausa no sale (la pausa
## ya las enseña).

@export var player: Player
## Segundos entre actualizaciones mientras se ve.
@export_range(0.05, 2.0, 0.05, "suffix:s") var refresh_interval: float = 0.25
## Píxeles que desplaza cada paso de la rueda.
@export_range(1, 400, 1, "suffix:px") var scroll_step: int = 60

var _refresh_left: float = 0.0

@onready var _panel: Control = %Panel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _stats_view: StatsView = %StatsView


func _ready() -> void:
	if player:
		_stats_view.show_stats(player.stats)
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if not is_showing() or wheel == null or not wheel.pressed:
		return
	if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_scroll.scroll_vertical += scroll_step
	elif wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
		_scroll.scroll_vertical -= scroll_step
	else:
		return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var held := Input.is_action_pressed(InputActions.SHOW_STATS) and not get_tree().paused
	if held != _panel.visible:
		_panel.visible = held
		if held:
			_refresh()
		return
	if held:
		_refresh_left -= delta
		if _refresh_left <= 0.0:
			_refresh()


## ¿Se ven ahora?
func is_showing() -> bool:
	return _panel.visible


## Las stats que enseña, en orden.
func shown_stats() -> Array[StringName]:
	return _stats_view.shown_stats()


func _refresh() -> void:
	_stats_view.refresh()
	_refresh_left = refresh_interval
