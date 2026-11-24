class_name BurstEmitter
extends Node3D
## Estallidos de partículas que salen con señales del EventBus: el humo al morir un enemigo (de su
## color), las chispas al golpear, los restos al romper algo y el polvo al salir un enemigo.
##
## Cada uno sale de una reserva fija de emisores, reutilizando el más viejo. Hay un tope por
## fotograma para que una bomba que mata a cien no dispare cien a la vez.

## Qué lo dispara.
enum Trigger { ENEMY_DIED, ENEMY_HIT, BREAKABLE_BROKEN, ENEMY_SPAWNED }

@export var trigger: Trigger = Trigger.ENEMY_DIED
## Escena del estallido: un [GPUParticles3D] de un solo disparo, sin emitir.
@export var effect: PackedScene
## Emisores en la reserva.
@export_range(1, 256, 1) var pool_size: int = 24
## Estallidos nuevos por fotograma como mucho.
@export_range(1, 64, 1) var max_per_frame: int = 8
## Desplazamiento desde el punto del evento (el humo, a media altura del enemigo).
@export var offset: Vector3 = Vector3.ZERO
## Tiñe cada estallido del color del enemigo (solo con [constant Trigger.ENEMY_DIED]).
@export var tint_by_enemy: bool = false

var _pool: Array[GPUParticles3D] = []
var _next: int = 0
var _frame: int = -1
var _bursts_this_frame: int = 0


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	for index: int in pool_size:
		var particles := effect.instantiate() as GPUParticles3D
		particles.emitting = false
		if tint_by_enemy:
			# Cada emisor con su propio material, para poder teñirlo sin teñir a los demás.
			particles.process_material = particles.process_material.duplicate()
		add_child(particles)
		_pool.append(particles)
	match trigger:
		Trigger.ENEMY_DIED:
			EventBus.enemy_died.connect(_on_enemy_died)
		Trigger.ENEMY_HIT:
			EventBus.enemy_damaged.connect(_on_enemy_damaged)
		Trigger.BREAKABLE_BROKEN:
			EventBus.breakable_broken.connect(_on_breakable_broken)
		Trigger.ENEMY_SPAWNED:
			EventBus.enemy_spawned.connect(_on_enemy_spawned)


## Lanza un estallido en [param at] (más [member offset]) con el color [param color]. Devuelve el
## emisor, o [code]null[/code] si ya se lanzaron [member max_per_frame] en este fotograma.
func burst(at: Vector3, color: Color = Color.WHITE) -> GPUParticles3D:
	var frame := Engine.get_process_frames()
	if frame != _frame:
		_frame = frame
		_bursts_this_frame = 0
	if _bursts_this_frame >= max_per_frame:
		return null
	_bursts_this_frame += 1
	var particles := _pool[_next]
	_next = (_next + 1) % _pool.size()
	particles.global_position = at + offset
	if tint_by_enemy:
		(particles.process_material as ParticleProcessMaterial).color = color
	particles.restart()
	return particles


func _on_enemy_died(enemy: Enemy) -> void:
	var color := enemy.data.color if enemy.data else Color.WHITE
	burst(enemy.global_position, color)


func _on_enemy_spawned(enemy: Enemy) -> void:
	burst(enemy.global_position)


func _on_enemy_damaged(at: Vector3, _amount: float, _info: DamageInfo) -> void:
	burst(at)


func _on_breakable_broken(_data: BreakableData, at: Vector3) -> void:
	burst(at)
