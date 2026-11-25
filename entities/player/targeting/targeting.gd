class_name Targeting
extends Node
## Adónde apuntan las armas del jugador. De serie, cada arma va a por lo más cercano. Manteniendo
## «apuntar» (clic derecho), van a por lo más cercano a lo que hay en el centro de la pantalla. Con
## «fijar objetivo» (clic central) se fija el jefe (o un miniboss, el más cercano) y todas le
## disparan mientras esté a su alcance; otra vez, lo suelta.

## La cámara del jugador: su centro es la mira.
@export var camera: Camera3D
## El cuerpo del jugador (para no apuntarse a sí mismo y para elegir el jefe más cercano).
@export var body: Node3D
## Hasta dónde llega la mira.
@export_range(5.0, 500.0, 1.0, "suffix:m") var aim_range: float = 80.0
## Contra qué choca la mira (el mundo y los cuerpos de los enemigos).
@export_flags_3d_physics var aim_mask: int = 0

var _aiming: bool = false
var _aim_point: Vector3 = Vector3.ZERO
var _locked: HurtboxComponent


func _physics_process(_delta: float) -> void:
	var aiming := Input.is_action_pressed(InputActions.AIM)
	if aiming != _aiming:
		_aiming = aiming
		EventBus.aim_changed.emit(aiming)
	if _aiming:
		_aim_point = _point_under_crosshair()
	if _locked and (not is_instance_valid(_locked) or _locked.health.is_dead()):
		release()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.LOCK_TARGET):
		toggle_lock()
		get_viewport().set_input_as_handled()


## ¿Está apuntando (manteniendo «apuntar»)?
func is_aiming() -> bool:
	return _aiming


## El punto del mundo bajo la mira.
func get_aim_point() -> Vector3:
	return _aim_point


## El objetivo fijado (la hurtbox del jefe), o null.
func get_locked() -> HurtboxComponent:
	return _locked if is_instance_valid(_locked) else null


## Fija el jefe vivo más cercano o, si ya había uno fijado, lo suelta.
func toggle_lock() -> void:
	if get_locked():
		release()
		return
	var best: Boss = null
	for node: Node in get_tree().get_nodes_in_group(Boss.GROUP):
		var boss := node as Boss
		if boss == null or not boss.is_alive():
			continue
		if best == null or _distance_to(boss) < _distance_to(best):
			best = boss
	if best:
		_locked = best.hurtbox
		EventBus.target_locked.emit(best)


## Suelta el objetivo fijado.
func release() -> void:
	_locked = null
	EventBus.target_locked.emit(null)


func _distance_to(target: Node3D) -> float:
	return body.global_position.distance_to(target.global_position) if is_instance_valid(body) else 0.0


func _point_under_crosshair() -> Vector3:
	if not is_instance_valid(camera):
		return _aim_point
	var from := camera.global_position
	var to := from - camera.global_basis.z * aim_range
	var query := PhysicsRayQueryParameters3D.create(from, to, aim_mask)
	var body_object := body as CollisionObject3D
	if body_object:
		query.exclude = [body_object.get_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return to
	var point: Vector3 = hit["position"]
	return point
