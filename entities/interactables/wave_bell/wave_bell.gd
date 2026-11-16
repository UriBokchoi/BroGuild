class_name WaveBell
extends Node3D
## Campana de la zona de práctica: con «interactuar» pone en marcha las oleadas de su
## [WaveDirector] o las para (retirando a los enemigos). Su aviso dice qué hará.

@export var interactable: Interactable
## Clave del aviso cuando las oleadas están paradas.
@export var start_prompt: StringName = &""
## Clave del aviso cuando están en marcha.
@export var stop_prompt: StringName = &""

var _director: WaveDirector


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	_refresh()


## Usa [param director] (lo asigna el nivel).
func use_director(director: WaveDirector) -> void:
	_director = director
	director.started.connect(_refresh)
	director.stopped.connect(_refresh)
	_refresh()


func _on_interacted(_by: Node3D) -> void:
	if _director == null:
		push_error("WaveBell: no tiene director.")
		return
	if _director.is_running():
		_director.stop()
	else:
		_director.start()


func _refresh() -> void:
	var running := _director != null and _director.is_running()
	interactable.prompt_key = stop_prompt if running else start_prompt
