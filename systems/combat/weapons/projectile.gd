@abstract
class_name Projectile
extends Node3D
## Proyectil de un [ProjectileWeapon]. Vuela recto y en cada tick traza un rayo del tramo que
## recorre, así no atraviesa nada aunque vaya muy rápido (y no necesita un Area3D). Al dar a una
## [HurtboxComponent] llama a [method _impact]; al dar al mundo, a [method _impact_world]; al acabar
## su vida (la duración del arma), termina. Se reutiliza (pool): al terminar se oculta y avisa con
## [signal finished].

signal finished

## Capas que detiene: las hurtbox de sus objetivos ([code]enemy_hurtbox[/code] o
## [code]player_hurtbox[/code]) y el mundo.
@export_flags_3d_physics var hit_mask: int = 0

## Arma que lo lanzó (su daño, sus stats y las de quien la lleva).
var weapon: ProjectileWeapon
var velocity: Vector3 = Vector3.ZERO

var _life: float = 0.0
var _query := PhysicsRayQueryParameters3D.new()
var _exclude: Array[RID] = []
var _rng: RandomNumberGenerator


func _ready() -> void:
	# Vuela por el mundo, no pegado a quien lo lanza.
	top_level = true
	_query.collide_with_areas = true
	_query.collide_with_bodies = true
	_rng = Rng.stream(Rng.Stream.COMBAT)
	_stop()


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		_finish()
		return
	var from := global_position
	_query.from = from
	_query.to = from + velocity * delta
	_query.collision_mask = hit_mask
	_query.exclude = _exclude
	var hit := get_world_3d().direct_space_state.intersect_ray(_query)
	if hit.is_empty():
		global_position = _query.to
		return
	var point: Vector3 = hit["position"]
	global_position = point
	var hurtbox := hit["collider"] as HurtboxComponent
	if hurtbox:
		_impact(hurtbox, point)
	else:
		_impact_world(point)


## Lo lanza [param from_weapon] desde [param origin] hacia [param direction] (normalizada).
func launch(from_weapon: ProjectileWeapon, origin: Vector3, direction: Vector3) -> void:
	weapon = from_weapon
	global_position = origin
	velocity = direction * weapon.projectile_speed()
	_life = weapon.duration()
	_exclude.clear()
	_face(direction)
	visible = true
	set_physics_process(true)
	reset_physics_interpolation()
	_launched()


## Golpea a [param hurtbox] con el daño del arma (y el daño %, el crítico y el empuje % de quien la
## lleva), empujándolo desde [param origin] (por defecto, desde donde está el proyectil).
func strike(hurtbox: HurtboxComponent, origin: Vector3 = Vector3.INF) -> float:
	var from := global_position if origin == Vector3.INF else origin
	var push := DamageCalc.push(from, hurtbox.get_center(), weapon.knockback())
	return hurtbox.receive(DamageCalc.attack(weapon.damage(), weapon.offense(), _rng, self, push))


## A partir de ahora, el rayo ya no se para en [param hurtbox] (ya le dio).
func ignore(hurtbox: HurtboxComponent) -> void:
	_exclude.append(hurtbox.get_rid())


## ¿Ya le dio a [param hurtbox]?
func ignores(hurtbox: HurtboxComponent) -> bool:
	return _exclude.has(hurtbox.get_rid())


## Olvida a quién le dio: puede volver a dar a todos (el hacha, al volver).
func clear_ignored() -> void:
	_exclude.clear()


## Cambia de rumbo hacia [param direction], a la misma velocidad.
func redirect(direction: Vector3) -> void:
	velocity = direction.normalized() * velocity.length()
	_face(direction)


## Vuelve a contar su vida desde el principio (al rebotar, por ejemplo).
func renew_life() -> void:
	_life = weapon.duration()


## Lo retira antes de tiempo (su arma dejó de atacar): termina sin hacer nada más.
func recall() -> void:
	_finish()


## Termina: se oculta y vuelve al pool.
func _finish() -> void:
	_stop()
	finished.emit()


## Dio a [param hurtbox] en [param point].
@abstract func _impact(hurtbox: HurtboxComponent, point: Vector3) -> void


## Dio al mundo en [param point]. Por defecto, termina.
func _impact_world(_point: Vector3) -> void:
	_finish()


## Acaba de salir (para preparar lo propio de cada proyectil).
func _launched() -> void:
	pass


## Deja de volar y de animarse, y se oculta.
func _stop() -> void:
	set_physics_process(false)
	set_process(false)
	visible = false


func _face(direction: Vector3) -> void:
	var up := Vector3.UP if absf(direction.normalized().y) < 0.99 else Vector3.FORWARD
	global_basis = Basis.looking_at(direction, up)
