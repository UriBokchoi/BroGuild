class_name HitFlash
extends Node
## Destello blanco breve al recibir un golpe, como capa encima del modelo; luego deja la que hubiera
## (el brillo de un élite). Solo trabaja mientras destella: con cientos de enemigos no cuesta nada.

## Vida cuyos golpes lo encienden.
@export var health: HealthComponent
## Modelo del que se iluminan todas sus mallas.
@export var visual: Node3D
## Mallas que se iluminan (el cuerpo: los ojos o los cuernos no hace falta). Vacío: todas las de
## [member visual].
@export var meshes: Array[GeometryInstance3D] = []
## Capa que se pone encima (blanca, suave y aditiva).
@export var material: Material
## Segundos que dura.
@export_range(0.01, 1.0, 0.01, "suffix:s") var duration: float = 0.08

var _meshes: Array[GeometryInstance3D] = []
## Capa de cada malla antes de destellar (para devolvérsela).
var _saved: Array[Material] = []
var _left: float = 0.0


func _ready() -> void:
	if not meshes.is_empty():
		_meshes = meshes.duplicate()
	elif visual:
		for mesh: Node in visual.find_children("*", "GeometryInstance3D", true, false):
			_meshes.append(mesh as GeometryInstance3D)
	if health:
		health.damaged.connect(_on_damaged)
	set_process(false)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		stop()


## ¿Está destellando?
func is_flashing() -> bool:
	return _left > 0.0


## Apaga el destello ya y devuelve la capa que había.
func stop() -> void:
	if not _saved.is_empty():
		for index: int in _meshes.size():
			# Si alguien cambió la capa mientras tanto (un élite al salir), se queda la suya.
			if _meshes[index].material_overlay == material:
				_meshes[index].material_overlay = _saved[index]
		_saved.clear()
	_left = 0.0
	set_process(false)


func _on_damaged(_amount: float, _info: DamageInfo) -> void:
	if material == null or _meshes.is_empty():
		return
	if _saved.is_empty():
		for mesh: GeometryInstance3D in _meshes:
			_saved.append(mesh.material_overlay)
			mesh.material_overlay = material
	_left = duration
	set_process(true)
