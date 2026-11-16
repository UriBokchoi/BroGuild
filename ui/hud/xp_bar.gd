class_name XpBar
extends HBoxContainer
## Experiencia y nivel del jugador en el HUD: el nivel a la izquierda y la barra hacia el siguiente.
## Se entera por [signal EventBus.player_xp_changed]. Estilo: variaciones [code]XpBar[/code] y
## [code]LevelLabel[/code] del Theme global.


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.player_xp_changed.is_connected(show_xp):
		EventBus.player_xp_changed.connect(show_xp)


## Muestra [param current] de [param needed] en el nivel [param level].
func show_xp(current: float, needed: float, level: int) -> void:
	var bar := %XpProgress as ProgressBar
	bar.max_value = needed
	bar.value = current
	(%LevelLabel as Label).text = tr(&"HUD_LEVEL") % level
