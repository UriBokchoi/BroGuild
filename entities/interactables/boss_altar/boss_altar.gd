class_name BossAltar
extends Node3D
## Altar del jefe (GDD §9): con «interactuar» pide sacar al jefe
## ([signal EventBus.boss_summon_requested]); el [BossEncounter] lo saca si el jugador lleva las
## llaves. Al acabar la ronda se activa solo: lo pide aunque falten. Muestra las llaves que lleva el
## jugador (una en cada ranura) y, con todas, una columna de luz que se ve desde lejos. Cuando sale
## el jefe, se apaga y ya no se usa.

@export var interactable: Interactable
## Dónde aparece el jefe.
@export var boss_spawn: Node3D
## Llaves en sus ranuras, en orden: se ve una por cada llave que lleva el jugador.
@export var key_slots: Array[Node3D] = []
## Columna de luz (con todas las llaves).
@export var beam: Node3D
## Aviso de «interactuar» si faltan llaves (con dos [code]%d[/code]: las que lleva y las que hacen
## falta).
@export var locked_key: StringName = &""
## Aviso de «interactuar» con todas las llaves.
@export var ready_key: StringName = &""

var _keys: int = 0
var _needed: int = 0
var _used: bool = false


func _enter_tree() -> void:
	if not EventBus.boss_keys_changed.is_connected(_on_keys_changed):
		EventBus.boss_keys_changed.connect(_on_keys_changed)
		EventBus.run_clock_changed.connect(_on_clock_changed)
		EventBus.boss_spawned.connect(_on_boss_spawned)


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	_refresh()


## ¿Ya sacó al jefe?
func is_used() -> bool:
	return _used


## ¿Tiene el jugador las llaves que hacen falta?
func is_ready() -> bool:
	return _keys >= _needed


func _refresh() -> void:
	for index: int in key_slots.size():
		key_slots[index].visible = index < _keys
	beam.visible = is_ready() and not _used
	# El Label que muestra el aviso no encuentra la clave y lo deja tal cual.
	interactable.prompt_key = ready_key if is_ready() else StringName(tr(locked_key) % [_keys, _needed])


func _request(forced: bool) -> void:
	if not _used:
		EventBus.boss_summon_requested.emit(boss_spawn.global_position, forced)


func _on_interacted(_by: Node3D) -> void:
	_request(false)


func _on_keys_changed(keys: int, needed: int) -> void:
	_keys = keys
	_needed = needed
	_refresh()


func _on_clock_changed(_seconds: float, overtime: bool) -> void:
	if overtime:
		_request(true)


func _on_boss_spawned(_name_key: StringName) -> void:
	_used = true
	interactable.enabled = false
	_refresh()
