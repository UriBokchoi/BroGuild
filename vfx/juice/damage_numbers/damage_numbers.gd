class_name DamageNumbers
extends Node3D
## Muestra un número de daño encima de cada enemigo golpeado (escucha
## [code]EventBus.enemy_damaged[/code]): el gameplay no sabe que existen (CLAUDE.md, regla 9). Los
## números salen de un pool; con demasiados a la vez, los nuevos no se muestran.

@export var style: DamageNumberStyle
## Números creados al empezar, para no crearlos en mitad del combate.
@export_range(0, 512, 1) var prewarm: int = 32
## Números en pantalla como mucho.
@export_range(1, 2048, 1) var max_numbers: int = 256

var _pool: NodePool
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = Rng.stream(Rng.Stream.COSMETIC)
	_pool = NodePool.new(_create_number, self)
	_pool.prewarm(prewarm)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)


## Números en pantalla ahora mismo.
func active_count() -> int:
	return _pool.size() - _pool.free_count()


func _on_enemy_damaged(at: Vector3, amount: float, info: DamageInfo) -> void:
	if _pool.free_count() == 0 and _pool.size() >= max_numbers:
		return
	var number := _pool.acquire() as DamageNumber
	number.launch(at, amount, info.critical, style, _rng)


func _create_number() -> Node:
	var number := DamageNumber.new()
	number.finished.connect(_pool.release.bind(number))
	return number
