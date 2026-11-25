class_name StepDust
extends Node3D
## Polvo pequeño a cada paso ([signal BodyBob.stepped]): un soplo a los pies, un paso a cada lado
## (pie izquierdo, pie derecho), con más polvo cuanto más rápido se va; andando muy despacio, nada.
## Solo visual. Vive en el mundo ([code]top_level[/code]): el polvo se queda donde cae.

## El balanceo que avisa de los pasos.
@export var bob: BodyBob
## Quien anda (sus pies y su velocidad, para saber a qué lado cae cada pie).
@export var walker: CharacterBody3D
## El soplo de polvo: una escena [GPUParticles3D] de un solo disparo.
@export var dust: PackedScene
## Distancia de cada pie al centro, de lado.
@export_range(0.0, 1.0, 0.01, "suffix:m") var foot_offset: float = 0.18
## Rapidez (respecto a la carrera) por debajo de la cual no levanta polvo.
@export_range(0.0, 2.0, 0.05) var min_ratio: float = 0.4
## Parte del polvo que suelta a la rapidez mínima (a la de carrera, todo).
@export_range(0.05, 1.0, 0.05) var min_amount: float = 0.4
## Soplos a la vez como mucho (si se acaban, se reutiliza el más viejo).
@export_range(1, 16, 1) var pool_size: int = 4

var _pool: Array[GPUParticles3D] = []
var _next: int = 0
var _left_foot: bool = true
var _steps: int = 0


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	for index: int in pool_size:
		var emitter := dust.instantiate() as GPUParticles3D
		emitter.emitting = false
		add_child(emitter)
		_pool.append(emitter)
	bob.stepped.connect(_on_stepped)


## Cuántos soplos ha soltado.
func get_steps() -> int:
	return _steps


func _on_stepped(ratio: float) -> void:
	if ratio < min_ratio or not is_instance_valid(walker):
		return
	_steps += 1
	var flat := Vector3(walker.velocity.x, 0.0, walker.velocity.z)
	var side := flat.normalized().cross(Vector3.UP) if flat.length() > 0.01 else Vector3.RIGHT
	var emitter := _pool[_next]
	_next = (_next + 1) % _pool.size()
	emitter.global_position = walker.global_position + side * foot_offset * (1.0 if _left_foot else -1.0)
	emitter.amount_ratio = clampf(lerpf(min_amount, 1.0, inverse_lerp(min_ratio, 1.0, ratio)), min_amount, 1.0)
	emitter.restart()
	_left_foot = not _left_foot
