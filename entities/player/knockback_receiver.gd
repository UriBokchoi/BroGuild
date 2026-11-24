class_name KnockbackReceiver
extends Node
## El empuje de los golpes que recibe el jugador: suma el de cada golpe y lo va soltando sobre el
## cuerpo mientras frena. Va aparte de la velocidad del movimiento, así los estados no tienen que
## saber de él.

## Cuerpo que se desplaza.
@export var body: CharacterBody3D
## Donde le llegan los golpes.
@export var hurtbox: HurtboxComponent
## Vida (para saber si el golpe llegó en sus segundos de invulnerabilidad).
@export var health: HealthComponent
## Lo que se frena el empuje cada segundo.
@export_range(1.0, 500.0, 1.0, "suffix:m/s²") var decay: float = 40.0
## Empuje máximo acumulado.
@export_range(1.0, 100.0, 0.5, "suffix:m/s") var max_speed: float = 25.0

var _push: Vector3 = Vector3.ZERO


func _ready() -> void:
	hurtbox.hurt.connect(_on_hurt)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	body.move_and_collide(_push * delta)
	_push = _push.move_toward(Vector3.ZERO, decay * delta)
	if _push.is_zero_approx():
		set_physics_process(false)


## Empuje que le queda.
func get_push() -> Vector3:
	return _push


func _on_hurt(info: DamageInfo, amount: float) -> void:
	if info.knockback == Vector3.ZERO or (amount <= 0.0 and not health.is_invulnerable()):
		return
	_push = (_push + info.knockback).limit_length(max_speed)
	set_physics_process(true)
