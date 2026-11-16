class_name RunClock
extends Label
## Reloj de la ronda en el HUD (minutos:segundos), arriba en el centro. Se entera por
## [signal EventBus.run_clock_changed]; sin ronda en marcha se oculta. Pasada la duración de la
## ronda se pone en rojo. Estilo: variaciones [code]ClockLabel[/code] y
## [code]ClockLabelOvertime[/code] del Theme global.


func _enter_tree() -> void:
	if not EventBus.run_clock_changed.is_connected(show_time):
		EventBus.run_clock_changed.connect(show_time)


func _ready() -> void:
	visible = false


## Muestra [param seconds] (en rojo si [param overtime]); con [param seconds] negativo, se oculta.
func show_time(seconds: float, overtime: bool) -> void:
	visible = seconds >= 0.0
	if not visible:
		return
	text = "%d:%02d" % [floori(seconds / 60.0), floori(seconds) % 60]
	theme_type_variation = &"ClockLabelOvertime" if overtime else &"ClockLabel"
