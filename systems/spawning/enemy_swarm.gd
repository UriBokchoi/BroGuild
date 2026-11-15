class_name EnemySwarm
extends Node3D
## Enemigos en juego. Los saca de un pool por tipo ([method spawn]), los mueve a todos en un único
## bucle hacia [member target] separándolos con un [SpatialHash] (sin comparar todos con todos) y
## los guarda en su pool cuando terminan de morir. Quien decide cuándo y dónde salen (el director
## de oleadas, el invocador de práctica) solo llama a [method spawn].

signal enemy_spawned(enemy: Enemy)
signal enemy_despawned(enemy: Enemy)

## A quién persiguen (el jugador). Vacío: se quedan quietos.
@export var target: Node3D
## Lado de las celdas del [SpatialHash]; parecido al radio de separación de los enemigos.
@export_range(0.5, 10.0, 0.1, "suffix:m") var cell_size: float = 2.0
## Un enemigo que cae por debajo de esta altura se retira (se cayó del mapa).
@export_range(-1000.0, 0.0, 1.0, "suffix:m") var kill_height: float = -50.0

var _pools: Dictionary[StringName, NodePool] = {}
var _active: Array[Enemy] = []
var _hash: SpatialHash


func _ready() -> void:
	_hash = SpatialHash.new(cell_size)


func _physics_process(delta: float) -> void:
	_hash.clear()
	for enemy: Enemy in _active:
		if enemy.is_alive():
			_hash.insert(enemy, enemy.global_position)
	var has_target := target != null
	var goal := target.global_position if has_target else Vector3.ZERO
	# Hacia atrás: un enemigo que termina de morir sale de la lista en mitad del bucle.
	for index: int in range(_active.size() - 1, -1, -1):
		var enemy := _active[index]
		if enemy.global_position.y < kill_height:
			_retire(enemy)
			continue
		var neighbors := _hash.positions_near(enemy.global_position, enemy.separation_radius(), enemy)
		enemy.physics_step(delta, goal, has_target, neighbors)


## Pone en juego un enemigo de [param enemy_data] con los pies en [param feet] y lo devuelve.
func spawn(enemy_data: EnemyData, feet: Vector3) -> Enemy:
	var enemy := _pool_for(enemy_data).acquire() as Enemy
	_active.append(enemy)
	enemy.spawn(feet)
	enemy_spawned.emit(enemy)
	return enemy


## Retira a todos los enemigos en juego.
func clear() -> void:
	for index: int in range(_active.size() - 1, -1, -1):
		_retire(_active[index])


## Enemigos en juego ahora mismo (vivos o terminando de morir).
func active_count() -> int:
	return _active.size()


func get_active() -> Array[Enemy]:
	return _active.duplicate()


func _pool_for(enemy_data: EnemyData) -> NodePool:
	if not _pools.has(enemy_data.id):
		_pools[enemy_data.id] = NodePool.new(_create.bind(enemy_data), self)
	return _pools[enemy_data.id]


func _create(enemy_data: EnemyData) -> Node:
	var enemy := enemy_data.scene.instantiate() as Enemy
	enemy.setup(enemy_data)
	enemy.despawned.connect(_on_despawned)
	return enemy


func _retire(enemy: Enemy) -> void:
	enemy.deactivate()
	_on_despawned(enemy)


func _on_despawned(enemy: Enemy) -> void:
	_active.erase(enemy)
	_pools[enemy.data.id].release(enemy)
	enemy_despawned.emit(enemy)
