class_name LockMarker
extends Node3D
## La marca encima del objetivo fijado con el clic central (un rombo rojo que flota y gira). Sigue al
## objetivo mientras esté fijado. Solo visual. Vive en el mundo (top_level).

## Altura sobre la cabeza del objetivo (su tamaño la sube: un jefe es grande).
@export_range(0.0, 20.0, 0.1, "suffix:m") var height: float = 1.5
## Vueltas por segundo.
@export_range(0.0, 5.0, 0.05) var spin: float = 0.5

var _target: Node3D


func _enter_tree() -> void:
	if not EventBus.target_locked.is_connected(follow):
		EventBus.target_locked.connect(follow)


func _ready() -> void:
	top_level = true
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		follow(null)
		return
	global_position = _top_of(_target) + Vector3.UP * height
	rotate_y(spin * TAU * delta)


## Sigue a [param target] (null: se oculta).
func follow(target: Node3D) -> void:
	_target = target
	visible = target != null
	set_process(visible)


## ¿Se está viendo?
func is_following(target: Node3D) -> bool:
	return visible and _target == target


## Lo más alto de [param target]: si es un enemigo, el doble de la altura del centro de su zona de
## golpe (que va a media altura del cuerpo); si no, 2 m sobre sus pies.
static func _top_of(target: Node3D) -> Vector3:
	var enemy := target as Enemy
	if enemy == null:
		return target.global_position + Vector3.UP * 2.0
	var center := enemy.hurtbox.get_center()
	return Vector3(center.x, center.y * 2.0 - target.global_position.y, center.z)
