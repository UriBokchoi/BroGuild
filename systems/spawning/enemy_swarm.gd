class_name EnemySwarm
extends Node3D
## Enemigos en juego. Los saca de un pool por tipo ([method spawn]), los mueve a todos en un único
## bucle hacia [member target] (separándose y trepando unos sobre otros con un [SpatialHash], sin
## comparar todos con todos) y los guarda en su pool cuando terminan de morir. Quien decide cuándo
## y dónde salen (el director de oleadas, el invocador de práctica) solo llama a [method spawn].
##
## Rendimiento: el rumbo de cada enemigo (perseguir, separarse, trepar) se recalcula cada
## [member steering_slices] ticks, repartidos entre ticks; la física los mueve en todos.

signal enemy_spawned(enemy: Enemy)
signal enemy_despawned(enemy: Enemy)

## Marca de un enemigo apoyado en el [SpatialHash] (sirve de apoyo para trepar).
const SETTLED_TAG: int = 1

## A quién persiguen (el jugador). Vacío: se quedan quietos.
@export var target: Node3D
## Lado de las celdas del [SpatialHash]; parecido al radio de separación de los enemigos.
@export_range(0.5, 10.0, 0.1, "suffix:m") var cell_size: float = 1.2
## Cada cuántos ticks recalcula su rumbo cada enemigo (1 = en todos; 3 = un tercio en cada tick).
@export_range(1, 8, 1) var steering_slices: int = 3
## Vecinos que mira cada enemigo como mucho (en una multitud bastan unos pocos).
@export_range(1, 64, 1) var max_neighbors: int = 8
## Un enemigo que cae por debajo de esta altura se retira (se cayó del mapa).
@export_range(-1000.0, 0.0, 1.0, "suffix:m") var kill_height: float = -50.0
## Proyectiles de enemigos en vuelo a la vez como mucho (con el máximo, los disparos nuevos no
## salen). 0 = sin máximo.
@export_range(0, 2000, 1, "or_greater") var projectile_limit: int = 80

## Proyectiles de los enemigos: viven aquí y no en quien dispara, así siguen volando aunque muera.
var projectiles: ProjectilePool

var _pools: Dictionary[StringName, NodePool] = {}
var _active: Array[Enemy] = []
## Enemigos vivos como estaban al empezar el tick, marcando los apoyados.
var _hash: SpatialHash
## Índice en [member _hash] de cada enemigo de [member _active] (−1 si no está apuntado).
var _slots: PackedInt32Array = PackedInt32Array()
var _tick: int = 0


func _ready() -> void:
	_hash = SpatialHash.new(cell_size)
	projectiles = ProjectilePool.new()
	projectiles.name = "Projectiles"
	projectiles.limit = projectile_limit
	add_child(projectiles)


func _physics_process(delta: float) -> void:
	_tick += 1
	_index_enemies()
	var has_target := target != null
	var goal := target.global_position if has_target else Vector3.ZERO
	var slice := _tick % steering_slices
	var slice_delta := delta * steering_slices
	# Hacia atrás: un enemigo que termina de morir sale de la lista en mitad del bucle.
	for index: int in range(_active.size() - 1, -1, -1):
		var enemy := _active[index]
		var at := enemy.global_position
		if at.y < kill_height:
			_retire(enemy)
			continue
		if not enemy.is_alive():
			enemy.physics_step(delta, goal, has_target, PackedVector3Array(), PackedVector3Array())
			continue
		if index % steering_slices != slice:
			continue
		var neighbors := PackedVector3Array()
		var footholds := PackedVector3Array()
		for near: int in _hash.indices_near(at, enemy.separation_radius(), _slots[index], max_neighbors):
			var spot := _hash.position_at(near)
			neighbors.append(spot)
			if _hash.tag_at(near) == SETTLED_TAG:
				footholds.append(spot)
		enemy.physics_step(slice_delta, goal, has_target, neighbors, footholds)


## Apunta dónde está cada enemigo vivo y si está apoyado, como estaban al empezar el tick (así el
## resultado no depende del orden del bucle).
func _index_enemies() -> void:
	_hash.clear()
	_slots.resize(_active.size())
	for index: int in _active.size():
		var enemy := _active[index]
		_slots[index] = -1
		if enemy.is_alive():
			var tag := SETTLED_TAG if enemy.is_settled() else 0
			_slots[index] = _hash.insert(enemy, enemy.global_position, tag)


## Pone en juego un enemigo de [param enemy_data] con los pies en [param feet] y lo devuelve.
func spawn(enemy_data: EnemyData, feet: Vector3) -> Enemy:
	var enemy := _pool_for(enemy_data).acquire() as Enemy
	_active.append(enemy)
	enemy.spawn(feet)
	enemy_spawned.emit(enemy)
	return enemy


## Retira a todos los enemigos en juego y sus proyectiles.
func clear() -> void:
	for index: int in range(_active.size() - 1, -1, -1):
		_retire(_active[index])
	projectiles.clear()


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
	enemy.setup(enemy_data, projectiles)
	enemy.despawned.connect(_on_despawned)
	return enemy


func _retire(enemy: Enemy) -> void:
	enemy.deactivate()
	_on_despawned(enemy)


func _on_despawned(enemy: Enemy) -> void:
	_active.erase(enemy)
	_pools[enemy.data.id].release(enemy)
	enemy_despawned.emit(enemy)
