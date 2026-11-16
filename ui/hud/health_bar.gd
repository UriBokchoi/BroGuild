class_name HealthBar
extends ProgressBar
## Vida del jugador en el HUD. Se entera por [signal EventBus.player_health_changed]. Estilo:
## variación [code]HealthBar[/code] del Theme global.


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.player_health_changed.is_connected(show_health):
		EventBus.player_health_changed.connect(show_health)


func _ready() -> void:
	show_percentage = false
	step = 0.0


## Muestra [param current] de [param maximum].
func show_health(current: float, maximum: float) -> void:
	max_value = maximum
	value = current
