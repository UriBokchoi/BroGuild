class_name Sword
extends Weapon
## Espada (GDD §6): cada golpe es un tajo en arco hacia su objetivo, alrededor de quien la lleva.
## Apunta también en vertical, al centro del enemigo (para dar a los de lo alto de una pila), con un
## límite de inclinación. Los proyectiles extra son más tajos seguidos, alternando el lado del
## barrido. Su alcance crece con el área, igual que el tajo.

## Escena del tajo (raíz [SwordSlash], dibujado con alcance 1 m).
@export var slash_scene: PackedScene
## Inclinación máxima del tajo hacia arriba o hacia abajo.
@export_range(0.0, 89.0, 1.0, "suffix:°") var max_pitch: float = 70.0
## Tajos que se crean de antemano.
@export_range(0, 16, 1) var prewarm_slashes: int = 2

var _slashes: NodePool


func _ready() -> void:
	super()
	_slashes = NodePool.new(_create_slash, self)
	_slashes.prewarm(prewarm_slashes)


func reach() -> float:
	return _weapon.reach * area_scale()


func _fire(target: Node3D, index: int) -> void:
	var slash := _slashes.acquire() as SwordSlash
	slash.position = Vector3.UP * aim_height
	slash.swing(_aim_direction(target), reach(), duration(), damage(), wielder_stats, index % 2 == 1, knockback())


## Dirección del tajo hacia el centro de [param target], con la inclinación limitada a
## [member max_pitch] (así nunca apunta recto arriba o abajo).
func _aim_direction(target: Node3D) -> Vector3:
	var to_target := TargetFinder.aim_point(target) - aim_origin()
	var flat := Vector3(to_target.x, 0.0, to_target.z)
	var flat_length := flat.length()
	var forward := flat / flat_length if flat_length > 0.001 else Vector3.FORWARD
	var limit := deg_to_rad(max_pitch)
	var pitch := clampf(atan2(to_target.y, flat_length), -limit, limit)
	return forward * cos(pitch) + Vector3.UP * sin(pitch)


func _create_slash() -> Node:
	var slash := slash_scene.instantiate() as SwordSlash
	slash.finished.connect(_slashes.release.bind(slash))
	return slash
