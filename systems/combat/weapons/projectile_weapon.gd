class_name ProjectileWeapon
extends Weapon
## Arma que dispara proyectiles (bastón, daga…): cada golpe es un proyectil que sale del pecho hacia
## el centro de su objetivo. Lo que hace al impactar lo decide la escena del proyectil
## ([Projectile]). Sus stats son un [ProjectileStats] (o un subtipo).

## Escena del proyectil: su raíz es un [Projectile].
@export var projectile_scene: PackedScene
## Proyectiles que se crean de antemano (si no usa un [member shared_pool]).
@export_range(0, 64, 1) var prewarm_projectiles: int = 4

## Pool compartido del que saca sus proyectiles, con su máximo a la vez (las armas de los enemigos:
## ver [ProjectilePool]). Se asigna antes de entrar en el árbol. Vacío: tiene su propio pool, hijo
## suyo, y sus proyectiles desaparecen al desarmarla.
var shared_pool: ProjectilePool

var _projectiles: NodePool
## Proyectiles de su propio pool en vuelo (o explotando).
var _flying: Array[Projectile] = []


func _ready() -> void:
	super()
	if shared_pool == null:
		_projectiles = NodePool.new(_create_projectile, self)
		_projectiles.prewarm(prewarm_projectiles)


## Velocidad de los proyectiles, con la velocidad de proyectil del personaje.
func projectile_speed() -> float:
	var own := (_weapon as ProjectileStats).projectile_speed
	return own * _percent(_offense.projectile_speed if _offense else 100.0)


func _fire(target: Node3D, _index: int) -> void:
	var projectile := _acquire()
	if projectile == null:
		# El pool compartido está en su máximo: este golpe se pierde.
		return
	var origin := aim_origin()
	projectile.chase_target = target
	projectile.launch(self, origin, (TargetFinder.aim_point(target) - origin).normalized())


func _acquire() -> Projectile:
	if shared_pool:
		return shared_pool.acquire(projectile_scene)
	var projectile := _projectiles.acquire() as Projectile
	_flying.append(projectile)
	return projectile


## Los proyectiles de su propio pool desaparecen (los del compartido siguen volando).
func _disarmed() -> void:
	for projectile: Projectile in _flying.duplicate():
		projectile.recall()


func _create_projectile() -> Node:
	var projectile := projectile_scene.instantiate() as Projectile
	projectile.finished.connect(_on_projectile_finished.bind(projectile))
	return projectile


func _on_projectile_finished(projectile: Projectile) -> void:
	_flying.erase(projectile)
	_projectiles.release(projectile)
