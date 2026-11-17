class_name LeapAttack
extends BossAttack
## Salto con onda (el «Burpee» del Ent-renador): se para y se agacha mientras un aro marca dónde va
## a caer (donde estaba el objetivo, como mucho a [member max_distance]); salta, cae ahí y suelta
## una [Shockwave] por el suelo que daña su contacto × [member damage_factor]. Se esquiva saltando
## por encima de la onda o alejándose antes de que llegue.

enum Phase { WINDUP, AIR, RECOVERY }

## Segundos agachado antes de saltar.
@export_range(0.0, 5.0, 0.05, "suffix:s") var windup: float = 0.8
## Segundos en el aire.
@export_range(0.2, 5.0, 0.05, "suffix:s") var air_time: float = 0.9
## Distancia máxima del salto.
@export_range(1.0, 100.0, 0.5, "suffix:m") var max_distance: float = 18.0
## Segundos quieto tras caer.
@export_range(0.0, 5.0, 0.05, "suffix:s") var recovery: float = 0.6
## Alto del modelo agachado (1 = normal).
@export_range(0.1, 1.0, 0.05) var crouch: float = 0.7
## Daño de la onda: su daño al tocar por esto.
@export_range(0.0, 20.0, 0.05) var damage_factor: float = 1.5
## Velocidad hacia abajo a partir de la cual cuenta que cae (para saber cuándo aterriza).
@export_range(0.1, 20.0, 0.1, "suffix:m/s") var falling_speed: float = 1.0
## Onda al caer.
@export var shockwave: Shockwave
## Aro que marca dónde va a caer.
@export var landing_marker: Node3D

var _phase: Phase = Phase.WINDUP
var _left: float = 0.0
var _landing: Vector3 = Vector3.ZERO
var _falling: bool = false


func _ready() -> void:
	landing_marker.visible = false


func begin(target: Vector3) -> void:
	var reach := flat(boss.global_position, target).limit_length(max_distance)
	_landing = Vector3(boss.global_position.x + reach.x, target.y, boss.global_position.z + reach.z)
	landing_marker.global_position = _landing
	landing_marker.visible = true
	_phase = Phase.WINDUP
	_left = windup


func step(delta: float, _target: Vector3) -> bool:
	_left -= delta
	match _phase:
		Phase.WINDUP:
			boss.move_flat(Vector3.ZERO)
			boss.face_toward(_landing, delta)
			boss.squash(lerpf(crouch, 1.0, maxf(_left, 0.0) / maxf(windup, 0.001)))
			if _left <= 0.0:
				_jump()
		Phase.AIR:
			if boss.linear_velocity.y < -falling_speed:
				_falling = true
			# Aterriza al dejar de caer (o, si algo lo frena, pasado el doble del tiempo en el aire).
			if (_falling and boss.linear_velocity.y > -falling_speed) or _left <= -air_time:
				_land()
		Phase.RECOVERY:
			boss.move_flat(Vector3.ZERO)
			if _left <= 0.0:
				return true
	return false


func cancel() -> void:
	landing_marker.visible = false
	shockwave.stop()
	boss.squash(1.0)


## Sale hacia [member _landing]: la velocidad que hace que la gravedad lo deje ahí en
## [member air_time] segundos.
func _jump() -> void:
	boss.squash(1.0)
	var gravity := -boss.get_gravity().y * boss.gravity_scale
	var horizontal := flat(boss.global_position, _landing) / air_time
	var rise := _landing.y - boss.global_position.y
	var vertical := (rise + 0.5 * gravity * air_time * air_time) / air_time
	boss.linear_velocity = Vector3(horizontal.x, vertical, horizontal.z)
	_phase = Phase.AIR
	_left = air_time
	_falling = false


func _land() -> void:
	boss.move_flat(Vector3.ZERO)
	landing_marker.visible = false
	shockwave.start(boss.global_position, boss.get_contact_damage() * damage_factor)
	_phase = Phase.RECOVERY
	_left = recovery
