class_name ChargeAttack
extends BossAttack
## Embestidas (las «Series» del Ent-renador): se para y apunta al objetivo mientras una franja en el
## suelo marca por dónde va a ir; luego sale disparado en línea recta [member distance] metros. Lo
## repite [member reps] veces. Mientras embiste, su contacto daña × [member damage_factor].

enum Phase { AIM, CHARGE }

## Embestidas seguidas.
@export_range(1, 10, 1) var reps: int = 3
## Segundos apuntando antes de la primera.
@export_range(0.0, 5.0, 0.05, "suffix:s") var windup: float = 0.8
## Segundos apuntando antes de cada una de las siguientes.
@export_range(0.0, 5.0, 0.05, "suffix:s") var rep_windup: float = 0.45
## Velocidad de la embestida.
@export_range(1.0, 100.0, 0.5, "suffix:m/s") var speed: float = 22.0
## Largo de cada embestida.
@export_range(1.0, 100.0, 0.5, "suffix:m") var distance: float = 16.0
## Daño al tocar durante la embestida: el normal por esto.
@export_range(0.0, 20.0, 0.05) var damage_factor: float = 1.5
## Franja que marca por dónde va a ir: mide 1 de largo hacia −Z desde su origen y se estira al largo
## de la embestida.
@export var lane: Node3D

var _phase: Phase = Phase.AIM
var _left: float = 0.0
var _reps_left: int = 0
var _direction: Vector3 = Vector3.FORWARD


func _ready() -> void:
	lane.visible = false


func begin(target: Vector3) -> void:
	_reps_left = reps
	_aim(target, windup)


func step(delta: float, target: Vector3) -> bool:
	_left -= delta
	if _phase == Phase.AIM:
		boss.move_flat(Vector3.ZERO)
		boss.face_toward(target, delta)
		_point_lane(target)
		if _left <= 0.0:
			_charge()
		return false
	boss.move_flat(_direction * speed)
	if _left > 0.0:
		return false
	_restore_contact()
	_reps_left -= 1
	if _reps_left <= 0:
		boss.move_flat(Vector3.ZERO)
		return true
	_aim(target, rep_windup)
	return false


func cancel() -> void:
	lane.visible = false
	_restore_contact()


func _aim(target: Vector3, seconds: float) -> void:
	_phase = Phase.AIM
	_left = seconds
	_point_lane(target)
	lane.visible = true


## Apunta la franja (y la dirección de la embestida) hacia [param target].
func _point_lane(target: Vector3) -> void:
	var toward := flat(boss.global_position, target)
	if toward.length_squared() > 0.0001:
		_direction = toward.normalized()
	var basis := Basis.looking_at(_direction)
	basis.z *= distance
	lane.global_transform = Transform3D(basis, boss.global_position)


func _charge() -> void:
	_phase = Phase.CHARGE
	_left = distance / speed
	lane.visible = false
	boss.contact_hitbox.base_damage = boss.get_contact_damage() * damage_factor
	# Cada embestida puede volver a dar aunque acabe de dar la anterior.
	boss.contact_hitbox.reset_hits()


func _restore_contact() -> void:
	boss.contact_hitbox.base_damage = boss.get_contact_damage()
