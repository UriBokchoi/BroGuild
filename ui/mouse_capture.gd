class_name MouseCapture
extends Node
## Dueño del modo del ratón: capturado para mirar con la cámara, salvo mientras alguna interfaz
## pida el cursor con [signal EventBus.cursor_requested] (el menú de pausa, el panel de
## depuración…). Va en la escena principal: el modo del ratón es de toda la partida.

var _requesters: Array[Object] = []


func _enter_tree() -> void:
	# En _enter_tree para no perder peticiones de nodos que estén listos antes que este.
	if not EventBus.cursor_requested.is_connected(_on_cursor_requested):
		EventBus.cursor_requested.connect(_on_cursor_requested)
	_apply()


## ¿Alguna interfaz pide el cursor?
func is_cursor_requested() -> bool:
	return not _requesters.is_empty()


func _on_cursor_requested(requester: Object, wants_cursor: bool) -> void:
	if wants_cursor and not _requesters.has(requester):
		_requesters.append(requester)
	elif not wants_cursor:
		_requesters.erase(requester)
	_apply()


func _apply() -> void:
	# Quien pidió el cursor y ya no existe no puede soltarlo: se olvida.
	for i: int in range(_requesters.size() - 1, -1, -1):
		if not is_instance_valid(_requesters[i]):
			_requesters.remove_at(i)
	var cursor := Input.MOUSE_MODE_VISIBLE if is_cursor_requested() else Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = cursor
