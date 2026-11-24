class_name DamageNumbers
extends Node3D
## Los números de daño encima de cada enemigo golpeado. Salen de un pool y, con un tope por
## fotograma: un golpe a cien enemigos solo enseñaría ruido y daba un tirón. El pool se prepara al
## empezar para que el primer golpe grande no tenga que hacerlo.

@export var style: DamageNumberStyle
## Números creados al empezar, para no crearlos en mitad del combate.
@export_range(0, 512, 1) var prewarm: int = 96
## Números en pantalla como mucho.
@export_range(1, 2048, 1) var max_numbers: int = 256
## Números nuevos como mucho en un mismo fotograma.
@export_range(1, 512, 1) var max_per_frame: int = 24

var _pool: NodePool
var _rng: RandomNumberGenerator
var _frame: int = -1
var _shown_this_frame: int = 0


func _ready() -> void:
	_rng = Rng.stream(Rng.Stream.COSMETIC)
	_pool = NodePool.new(_create_number, self)
	_pool.prewarm(prewarm)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)


## Números en pantalla ahora mismo.
func active_count() -> int:
	return _pool.size() - _pool.free_count()


func _on_enemy_damaged(at: Vector3, amount: float, info: DamageInfo) -> void:
	var frame := Engine.get_process_frames()
	if frame != _frame:
		_frame = frame
		_shown_this_frame = 0
	if _shown_this_frame >= max_per_frame:
		return
	if _pool.free_count() == 0 and _pool.size() >= max_numbers:
		return
	_shown_this_frame += 1
	var number := _pool.acquire() as DamageNumber
	number.launch(at, amount, info.critical, style, _rng, info.kind)


func _create_number() -> Node:
	var number := DamageNumber.new()
	number.prepare(style)
	number.finished.connect(_pool.release.bind(number))
	return number
