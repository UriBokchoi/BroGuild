class_name FxBurst
extends Node3D
## Un efecto de un solo disparo (lo que se ve al coger un power-up). [method play] vuelve a soltar
## todas sus partículas ([GPUParticles3D] hijas), abre sus aros en el suelo y sube lo que tenga que
## subir (el sombrero del hongo de la bomba). El temblor de cámara y el destello de pantalla los pide
## quien lo lanza ([PowerUpFx]), con [member trauma] y [member flash].

## Aros en el suelo que se abren desde el centro hasta [member ring_radius] mientras se apagan: un
## PlaneMesh de 2 × 2 con [code]ground_ring.gdshader[/code].
@export var rings: Array[GeometryInstance3D] = []
@export_range(0.5, 60.0, 0.5, "suffix:m") var ring_radius: float = 6.0
@export_range(0.05, 5.0, 0.05, "suffix:s") var ring_time: float = 0.5
## Ancho del aro, en partes del radio.
@export_range(0.01, 1.0, 0.01) var ring_band: float = 0.08
## Lo que sube al lanzarse (desde donde está en la escena): cuánto y en cuántos segundos.
@export var risers: Array[Node3D] = []
@export_range(0.0, 30.0, 0.5, "suffix:m") var rise_height: float = 0.0
@export_range(0.05, 5.0, 0.05, "suffix:s") var rise_time: float = 1.0
## Temblor de cámara que pide (0 = ninguno).
@export_range(0.0, 1.0, 0.05) var trauma: float = 0.0
## Destello de pantalla: su color (con su opacidad; transparente = ninguno) y cuánto tarda en irse.
@export var flash: Color = Color(1.0, 1.0, 1.0, 0.0)
@export_range(0.05, 2.0, 0.05, "suffix:s") var flash_time: float = 0.3

var _rise_from: Array[float] = []
var _tween: Tween


func _ready() -> void:
	for riser: Node3D in risers:
		_rise_from.append(riser.position.y)
	for ring: GeometryInstance3D in rings:
		ring.scale = Vector3(ring_radius, 1.0, ring_radius)
		ring.set_instance_shader_parameter(&"band", ring_band)
		ring.visible = false


## Lo lanza otra vez desde el principio.
func play() -> void:
	for node: Node in find_children("*", "GPUParticles3D", true, false):
		(node as GPUParticles3D).restart()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	for ring: GeometryInstance3D in rings:
		ring.visible = true
		_tween.tween_method(_open_ring.bind(ring), 0.0, 1.0, ring_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	for index: int in risers.size():
		var riser := risers[index]
		riser.position.y = _rise_from[index]
		_tween.tween_property(riser, ^"position:y", _rise_from[index] + rise_height, rise_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


## ¿Sigue algo en marcha (aros o partículas)?
func is_playing() -> bool:
	if _tween and _tween.is_running():
		return true
	for node: Node in find_children("*", "GPUParticles3D", true, false):
		if (node as GPUParticles3D).emitting:
			return true
	return false


func _open_ring(progress: float, ring: GeometryInstance3D) -> void:
	ring.set_instance_shader_parameter(&"progress", progress)
	ring.set_instance_shader_parameter(&"fade", 1.0 - progress)
	if progress >= 1.0:
		ring.visible = false
