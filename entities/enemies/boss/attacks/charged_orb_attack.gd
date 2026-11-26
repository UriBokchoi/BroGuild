class_name ChargedOrbAttack
extends BossAttack
## Bola roja (lo que era el «Burpee» de los jefes): se planta y carga una bola roja en el suelo donde
## va el jugador (donde está más lo que se mueve en [member lead_time] s, como mucho a
## [member max_distance]). Mientras apunta ([member aim_time]) la bola le sigue; luego se queda quieta
## [member lock_time] s mientras crece y, al acabar, revienta y daña lo que haya dentro (una
## [Shockwave] rápida de su radio, con su daño al tocar × [member damage_factor]). Da tiempo a salir.

enum Phase { AIM, LOCKED, RECOVERY }

## Segundos en que la bola sigue hacia dónde va el jugador.
@export_range(0.0, 5.0, 0.05, "suffix:s") var aim_time: float = 0.6
## Segundos con la bola quieta antes de reventar (para esquivarla).
@export_range(0.1, 5.0, 0.05, "suffix:s") var lock_time: float = 1.2
## Segundos quieto tras reventar.
@export_range(0.0, 5.0, 0.05, "suffix:s") var recovery: float = 0.6
## Cuánto se adelanta a hacia dónde va el jugador (segundos de su movimiento).
@export_range(0.0, 3.0, 0.05, "suffix:s") var lead_time: float = 0.8
## Distancia máxima del jefe a la bola.
@export_range(1.0, 100.0, 0.5, "suffix:m") var max_distance: float = 20.0
## Daño al reventar: su daño al tocar por esto.
@export_range(0.0, 20.0, 0.05) var damage_factor: float = 1.3
## Alto del modelo mientras carga (1 = normal).
@export_range(0.1, 1.0, 0.05) var crouch: float = 0.75
## Qué tamaño tiene la bola al empezar a cargar (parte de su radio).
@export_range(0.0, 1.0, 0.05) var start_size: float = 0.2
## La explosión: su radio es el de la bola.
@export var shockwave: Shockwave
## Aro en el suelo que marca hasta dónde llega (un plano de 2 × 2).
@export var marker: GeometryInstance3D
## La bola (una esfera de radio 1, que crece).
@export var orb: GeometryInstance3D

var _phase: Phase = Phase.AIM
var _left: float = 0.0
var _point: Vector3 = Vector3.ZERO
var _last_target: Vector3 = Vector3.ZERO
var _target_velocity: Vector3 = Vector3.ZERO
var _has_last: bool = false


func _ready() -> void:
	_hide()


func begin(target: Vector3) -> void:
	_last_target = target
	_has_last = true
	_target_velocity = Vector3.ZERO
	_point = _aim_point(target)
	_phase = Phase.AIM
	_left = aim_time
	marker.visible = true
	orb.visible = true
	_show(0.0)


func step(delta: float, target: Vector3) -> bool:
	_left -= delta
	boss.move_flat(Vector3.ZERO)
	_track(delta, target)
	match _phase:
		Phase.AIM:
			_point = _aim_point(target)
			boss.face_toward(_point, delta)
			boss.squash(crouch)
			_show(0.0)
			if _left <= 0.0:
				_phase = Phase.LOCKED
				_left = lock_time
		Phase.LOCKED:
			_show(1.0 - maxf(_left, 0.0) / maxf(lock_time, 0.001))
			if _left <= 0.0:
				_burst()
		Phase.RECOVERY:
			boss.squash(lerpf(crouch, 1.0, 1.0 - maxf(_left, 0.0) / maxf(recovery, 0.001)))
			if _left <= 0.0:
				return true
	return false


func cancel() -> void:
	_hide()
	shockwave.stop()
	boss.squash(1.0)


## Dónde está (o estará) la bola ahora.
func get_point() -> Vector3:
	return _point


func get_phase() -> Phase:
	return _phase


## Hacia dónde va el jugador: su posición más su movimiento en [member lead_time], en el suelo y a lo
## sumo a [member max_distance] del jefe.
func _aim_point(target: Vector3) -> Vector3:
	var ahead := target + Vector3(_target_velocity.x, 0.0, _target_velocity.z) * lead_time
	var reach := flat(boss.global_position, ahead).limit_length(max_distance)
	return Vector3(boss.global_position.x + reach.x, target.y, boss.global_position.z + reach.z)


## Lo que se mueve el objetivo (suavizado), de un tick al siguiente.
func _track(delta: float, target: Vector3) -> void:
	if _has_last and delta > 0.0:
		_target_velocity = _target_velocity.lerp((target - _last_target) / delta, 0.5)
	_last_target = target
	_has_last = true


## La bola y su aro en [member _point], la bola al tamaño de [param progress] (0–1) de su carga.
func _show(progress: float) -> void:
	var radius := shockwave.radius
	marker.global_position = _point
	marker.scale = Vector3.ONE * radius
	orb.global_position = _point
	orb.scale = Vector3.ONE * radius * lerpf(start_size, 1.0, progress)


func _burst() -> void:
	_hide()
	shockwave.start(_point, boss.get_contact_damage() * damage_factor)
	_phase = Phase.RECOVERY
	_left = recovery


func _hide() -> void:
	if marker:
		marker.visible = false
	if orb:
		orb.visible = false
