class_name ChargeShrine
extends Node3D
## Santuario de carga, como los de Megabonk: mientras el jugador está en su zona (un aro en el suelo)
## se va cargando; al llenarse ofrece elegir una mejora de stats entre varias, cada una con su
## rareza. Si el jugador sale, la carga se queda donde estaba. Se usa una vez.

## Cómo es (tiempo de carga, zona y mejoras).
@export var data: ChargeShrineData
## Zona que detecta al jugador (su forma se ajusta al radio de los datos).
@export var zone: Area3D
## El aro del borde de la zona y el que se abre desde el centro con la carga (ground_ring.gdshader).
@export var edge_ring: GeometryInstance3D
@export var charge_ring: GeometryInstance3D
## Lo que se ve mientras se puede usar (aros y columna de luz).
@export var glow: Node3D

## Azar de lo que ofrece. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## Rng.
var rng: RandomNumberGenerator

var _charge: float = 0.0
var _used: bool = false
var _player: Player


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	var shape := CylinderShape3D.new()
	shape.radius = data.reach
	shape.height = 4.0
	(zone.get_child(0) as CollisionShape3D).shape = shape
	edge_ring.scale = Vector3(data.reach, 1.0, data.reach)
	charge_ring.scale = edge_ring.scale
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	_show_charge()
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _used or not is_instance_valid(_player):
		set_physics_process(false)
		return
	_charge = minf(_charge + delta / data.charge_time, 1.0)
	_show_charge()
	if _charge >= 1.0:
		offer()


## Lo que lleva cargado (0–1).
func get_charge() -> float:
	return _charge


func is_used() -> bool:
	return _used


## Ofrece las mejoras (con la Suerte del jugador que está dentro) y se apaga. Una vez.
func offer() -> void:
	if _used:
		return
	_used = true
	glow.visible = false
	set_physics_process(false)
	var luck := _player.stats.get_value(&"luck") if is_instance_valid(_player) else 0.0
	EventBus.stat_choice_offered.emit(StatOffer.roll(data.stats, data.choices, data.rarities, luck, rng))


func _show_charge() -> void:
	charge_ring.set_instance_shader_parameter(&"progress", _charge)
	charge_ring.visible = _charge > 0.0


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player and not _used:
		_player = player
		set_physics_process(true)


func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player = null
