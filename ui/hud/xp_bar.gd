class_name XpBar
extends HBoxContainer
## Experiencia y nivel del jugador en el HUD: el nivel a la izquierda y la barra hacia el siguiente.
## Se entera por [signal EventBus.player_xp_changed]. La barra se llena suave ([UiMotion]); al subir
## de nivel empieza de nuevo al momento y el número del nivel da un salto. Estilo: variaciones
## [code]XpBar[/code] y [code]LevelLabel[/code] del Theme global.

var _level: int = -1
var _slide: Tween


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.player_xp_changed.is_connected(show_xp):
		EventBus.player_xp_changed.connect(show_xp)


## Muestra [param current] de [param needed] en el nivel [param level].
func show_xp(current: float, needed: float, level: int) -> void:
	var bar := %XpProgress as ProgressBar
	var label := %LevelLabel as Label
	if _slide and _slide.is_valid():
		_slide.kill()
	bar.max_value = needed
	if level != _level:
		bar.value = current
		label.text = tr(&"HUD_LEVEL") % level
		# El primero no salta: es el nivel con el que empieza.
		if _level >= 0:
			UiMotion.pop(label)
		_level = level
	else:
		_slide = UiMotion.slide(bar, current)
