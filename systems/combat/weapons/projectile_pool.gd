class_name ProjectilePool
extends Node
## Proyectiles que comparten muchas armas (las de los enemigos): un [NodePool] por escena de
## proyectil y un máximo en vuelo a la vez. Vive en el nivel, no en quien dispara, así sus disparos
## siguen volando aunque muera. Lo crea el [EnemySwarm] y lo reparte a las armas de sus enemigos.

## Proyectiles en vuelo a la vez como mucho (rendimiento y legibilidad): con el máximo alcanzado,
## los disparos nuevos no salen. 0 = sin máximo.
@export_range(0, 2000, 1, "or_greater") var limit: int = 0

var _pools: Dictionary[PackedScene, NodePool] = {}
var _flying: Array[Projectile] = []


## Un proyectil libre de [param scene] para lanzarlo ya, o [code]null[/code] si ya hay
## [member limit] en vuelo.
func acquire(scene: PackedScene) -> Projectile:
	if limit > 0 and _flying.size() >= limit:
		return null
	var projectile := _pool_for(scene).acquire() as Projectile
	_flying.append(projectile)
	return projectile


## Retira todos los proyectiles en vuelo.
func clear() -> void:
	for projectile: Projectile in _flying.duplicate():
		projectile.recall()


## Proyectiles en vuelo ahora mismo.
func flying_count() -> int:
	return _flying.size()


func _pool_for(scene: PackedScene) -> NodePool:
	if not _pools.has(scene):
		_pools[scene] = NodePool.new(_create.bind(scene), self)
	return _pools[scene]


func _create(scene: PackedScene) -> Node:
	var projectile := scene.instantiate() as Projectile
	projectile.finished.connect(_on_finished.bind(projectile, scene))
	return projectile


func _on_finished(projectile: Projectile, scene: PackedScene) -> void:
	_flying.erase(projectile)
	_pools[scene].release(projectile)
