class_name RunFlow
extends RefCounted
## Reintentar y volver al menú desde las pantallas de la partida (pausa, resultados). Dentro del
## juego completo lo atiende [Game] por el [code]EventBus[/code]; con el nivel ejecutado solo (F6),
## nadie escucha y se hace aquí: reintentar recarga la escena y salir cierra el juego.


## Empieza otra partida en el mismo nivel.
static func retry(tree: SceneTree) -> void:
	if EventBus.retry_requested.has_connections():
		EventBus.retry_requested.emit()
	else:
		tree.reload_current_scene()


## Deja la partida y vuelve al menú principal.
static func to_main_menu(tree: SceneTree) -> void:
	if EventBus.main_menu_requested.has_connections():
		EventBus.main_menu_requested.emit()
	else:
		tree.quit()
