class_name BossPortal
extends Node3D
## El portal del jefe (GDD §9): un aro de piedra con un remolino y, delante, una peana con las
## ranuras de las llaves. Al usarlo pide sacar al jefe, y al acabar la ronda lo pide solo.
##
## El remolino dice en qué punto está: apagado, vivo con todas las llaves, y dorado y abierto con el
## jefe vencido. Abierto, avisa de dónde está (para la flecha) y cruzarlo pasa el nivel.

@export var interactable: Interactable
## Dónde aparece el jefe.
@export var boss_spawn: Node3D
## Llaves en sus ranuras, en orden: se ve una por cada llave que lleva el jugador.
@export var key_slots: Array[Node3D] = []
## Columna de luz (con todas las llaves).
@export var beam: Node3D
## El remolino del aro (con [code]portal_vortex.gdshader[/code]: su parámetro de instancia
## [code]charge[/code] va de 0, apagado, a 1, abierto).
@export var vortex: GeometryInstance3D
## Zona dentro del aro que, abierto el portal, pasa el nivel al cruzarla.
@export var exit_area: Area3D
## Aviso de «interactuar» si faltan llaves (con dos [code]%d[/code]: las que lleva y las que hacen
## falta).
@export var locked_key: StringName = &""
## Aviso de «interactuar» con todas las llaves.
@export var ready_key: StringName = &""
## Cuánto se aviva el remolino en cada punto (0 = apagado, 1 = abierto).
@export_range(0.0, 1.0, 0.05) var idle_charge: float = 0.15
@export_range(0.0, 1.0, 0.05) var ready_charge: float = 0.5
## Segundos que tarda en abrirse del todo al vencer al jefe.
@export_range(0.05, 5.0, 0.05, "suffix:s") var open_time: float = 1.0
## Escondido (sin verse ni chocar) hasta que se abre: en la arena final aparece al vencer al jefe.
@export var hidden_until_open: bool = false

var _keys: int = 0
var _needed: int = 0
var _used: bool = false
var _open: bool = false
var _crossed: bool = false


func _enter_tree() -> void:
	if not EventBus.boss_keys_changed.is_connected(_on_keys_changed):
		EventBus.boss_keys_changed.connect(_on_keys_changed)
		EventBus.run_clock_changed.connect(_on_clock_changed)
		EventBus.boss_spawned.connect(_on_boss_spawned)
		EventBus.boss_defeated.connect(_on_boss_defeated)


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	exit_area.body_entered.connect(_on_exit_entered)
	exit_area.monitoring = false
	_refresh()
	if hidden_until_open and not _open:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED


## ¿Ya sacó al jefe?
func is_used() -> bool:
	return _used


## ¿Tiene el jugador las llaves que hacen falta?
func is_ready() -> bool:
	return _keys >= _needed


## ¿Está abierto (jefe vencido: cruzarlo pasa el nivel)?
func is_open() -> bool:
	return _open


## Dónde está la puerta: el centro del aro.
func exit_position() -> Vector3:
	return exit_area.global_position


func _refresh() -> void:
	for index: int in key_slots.size():
		key_slots[index].visible = index < _keys
	beam.visible = is_ready() and not _used
	if not _open:
		vortex.set_instance_shader_parameter(&"charge", ready_charge if is_ready() or _used else idle_charge)
	# El Label que muestra el aviso no encuentra la clave y lo deja tal cual.
	interactable.prompt_key = ready_key if is_ready() else StringName(tr(locked_key) % [_keys, _needed])


func _request(forced: bool) -> void:
	if not _used:
		EventBus.boss_summon_requested.emit(boss_spawn.global_position, forced)


## Se abre: el remolino se vuelve dorado poco a poco y la puerta deja pasar.
func _open_portal() -> void:
	_open = true
	if hidden_until_open:
		_appear()
	exit_area.set_deferred(&"monitoring", true)
	var tween := create_tween()
	tween.tween_method(
		func(charge: float) -> void: vortex.set_instance_shader_parameter(&"charge", charge),
		ready_charge, 1.0, open_time
	)
	EventBus.boss_portal_opened.emit(exit_position())


## Sale del suelo creciendo (el que estaba escondido).
func _appear() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	scale = Vector3.ONE * 0.01
	create_tween().tween_property(self, ^"scale", Vector3.ONE, open_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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


func _on_boss_defeated(_victory_key: StringName, _seconds: float, _bonus: float) -> void:
	if not _open:
		_open_portal()


func _on_exit_entered(body: Node3D) -> void:
	# Solo cuenta el jugador, y una vez.
	if _open and not _crossed and body is Player:
		_crossed = true
		EventBus.level_exit_reached.emit()
