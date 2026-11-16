class_name ProjectileWeapon
extends Weapon
## Arma que dispara proyectiles (bastón, daga…): cada golpe es un proyectil que sale del pecho hacia
## el centro de su objetivo. Lo que hace al impactar lo decide la escena del proyectil
## ([Projectile]). Sus stats son un [ProjectileStats] (o un subtipo).

## Escena del proyectil: su raíz es un [Projectile].
@export var projectile_scene: PackedScene
## Proyectiles que se crean de antemano.
@export_range(0, 64, 1) var prewarm_projectiles: int = 4

var _projectiles: NodePool
## Proyectiles en vuelo (o explotando).
var _flying: Array[Projectile] = []


func _ready() -> void:
	super()
	_projectiles = NodePool.new(_create_projectile, self)
	_projectiles.prewarm(prewarm_projectiles)


## Velocidad de los proyectiles, con la velocidad de proyectil del personaje.
func projectile_speed() -> float:
	var own := (_weapon as ProjectileStats).projectile_speed
	return own * _percent(_offense.projectile_speed if _offense else 100.0)


func _fire(target: Node3D, _index: int) -> void:
	var origin := aim_origin()
	var direction := (TargetFinder.aim_point(target) - origin).normalized()
	var projectile := _projectiles.acquire() as Projectile
	_flying.append(projectile)
	projectile.launch(self, origin, direction)


## Sus proyectiles en juego desaparecen: si muere quien la lleva, sus disparos no llegan.
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
