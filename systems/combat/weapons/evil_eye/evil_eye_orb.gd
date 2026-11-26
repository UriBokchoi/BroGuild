class_name EvilEyeOrb
extends Projectile
## Orbe del Mal de ojo: rojo y con estela, persigue a su objetivo girando hacia él. Al dar a un enemigo
## le hace el daño del arma; si es crítico, revienta y daña también a los de alrededor (radio de
## explosión por el área). Después salta al enemigo más cercano que no haya tocado, si le quedan
## rebotes; si no, termina.

## Orbe que vuela.
@export var orb: Node3D
## Estela (partículas que se quedan en el mundo).
@export var trail: GPUParticles3D
## Esfera de la explosión (radio 1, con el shader de la del bastón, en rojo).
@export var blast: GeometryInstance3D
## Segundos que se ve la explosión.
@export_range(0.05, 2.0, 0.01, "suffix:s") var blast_time: float = 0.25
## Enemigos que puede alcanzar una explosión como mucho.
@export_range(1, 256, 1) var max_targets: int = 64
## Enemigos entre los que busca el siguiente al rebotar.
@export_range(1, 64, 1) var bounce_candidates: int = 8

var _finder: TargetFinder
var _bounces_left: int = 0
var _blast_radius: float = 0.0
var _blast_age: float = -1.0
## Terminó mientras se veía la explosión: vuelve al pool cuando acabe.
var _ending: bool = false


func _physics_process(delta: float) -> void:
	if visible and _can_chase():
		_steer(delta)
	super(delta)


func _process(delta: float) -> void:
	_blast_age += delta
	var progress := clampf(_blast_age / blast_time, 0.0, 1.0)
	blast.scale = Vector3.ONE * _blast_radius * (0.35 + 0.65 * (1.0 - pow(1.0 - progress, 3.0)))
	blast.set_instance_shader_parameter(&"progress", progress)
	if progress >= 1.0:
		set_process(false)
		blast.visible = false
		if _ending:
			_ending = false
			super._finish()


func _launched() -> void:
	if _finder == null:
		_finder = TargetFinder.new(weapon.target_mask)
	_bounces_left = _stats().bounces
	_ending = false
	blast.visible = false
	orb.visible = true
	trail.restart()
	trail.emitting = true


## Rebotes que le quedan.
func bounces_left() -> int:
	return _bounces_left


## Radio de la explosión de un crítico ahora: el de sus stats por el área del arma.
func explosion_radius() -> float:
	return _stats().explosion_radius * weapon.area_scale()


func _impact(hurtbox: HurtboxComponent, point: Vector3) -> void:
	strike(hurtbox)
	ignore(hurtbox)
	if last_critical:
		_explode(point, hurtbox)
	if _bounces_left <= 0:
		_finish()
		return
	var next := _next_target(point)
	if next == null:
		_finish()
		return
	_bounces_left -= 1
	chase_target = next
	redirect(TargetFinder.aim_point(next) - point)
	renew_life()


## Termina; si se está viendo su explosión, deja de volar y vuelve al pool cuando acabe.
func _finish() -> void:
	trail.emitting = false
	if is_processing():
		set_physics_process(false)
		orb.visible = false
		_ending = true
		return
	super()


## Gira hacia su objetivo, más deprisa cuanto mayor su [member EvilEyeStats.homing].
func _steer(delta: float) -> void:
	var wanted := TargetFinder.aim_point(chase_target) - global_position
	if wanted.length_squared() < 0.0001:
		return
	var turn := clampf(_stats().homing * delta, 0.0, 1.0)
	redirect(velocity.normalized().lerp(wanted.normalized(), turn))


## ¿Tiene a quién perseguir? (Su objetivo sigue en el juego y se le puede dar.)
func _can_chase() -> bool:
	var hurtbox := chase_target as HurtboxComponent
	return _stats().homing > 0.0 and is_instance_valid(hurtbox) and hurtbox.monitorable \
		and hurtbox.is_visible_in_tree() and not ignores(hurtbox)


## Revienta en [param point]: daña a los enemigos del radio menos a [param struck] (ya le dio).
func _explode(point: Vector3, struck: HurtboxComponent) -> void:
	_blast_radius = explosion_radius()
	var space := get_world_3d().direct_space_state
	for found: Node3D in _finder.nearest(space, point, _blast_radius, max_targets):
		var hurtbox := found as HurtboxComponent
		if hurtbox and hurtbox != struck:
			strike(hurtbox, point)
	blast.global_position = point
	blast.visible = true
	_blast_age = 0.0
	set_process(true)


func _next_target(point: Vector3) -> HurtboxComponent:
	var space := get_world_3d().direct_space_state
	for found: Node3D in _finder.nearest(space, point, _stats().bounce_range, bounce_candidates):
		var hurtbox := found as HurtboxComponent
		if hurtbox and not ignores(hurtbox):
			return hurtbox
	return null


func _stats() -> EvilEyeStats:
	return weapon.stats.get_resolved(EvilEyeStats) as EvilEyeStats
