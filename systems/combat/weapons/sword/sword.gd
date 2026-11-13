class_name Sword
extends Weapon
## Espada (GDD §6): cada golpe es un tajo en arco hacia su objetivo, alrededor de quien la lleva.
## Los proyectiles extra son más tajos seguidos, alternando el lado del barrido. Su alcance crece
## con el área, igual que el tajo.

## Escena del tajo (raíz [SwordSlash], dibujado con alcance 1 m).
@export var slash_scene: PackedScene
## Altura del tajo sobre los pies.
@export_range(0.0, 3.0, 0.05, "suffix:m") var slash_height: float = 0.9
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
	var direction := target.global_position - global_position
	direction.y = 0.0
	if direction.is_zero_approx():
		direction = Vector3.FORWARD
	var slash := _slashes.acquire() as SwordSlash
	slash.position = Vector3.UP * slash_height
	slash.swing(direction.normalized(), reach(), duration(), damage(), wielder_stats, index % 2 == 1)


func _create_slash() -> Node:
	var slash := slash_scene.instantiate() as SwordSlash
	slash.finished.connect(_slashes.release.bind(slash))
	return slash
