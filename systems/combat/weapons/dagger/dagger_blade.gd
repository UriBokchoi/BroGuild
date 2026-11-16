class_name DaggerBlade
extends Projectile
## Daga lanzada: rápida, da a un solo enemigo. Si le quedan rebotes, salta al enemigo más cercano
## (que aún no haya tocado) dentro de su distancia de rebote, con todo su daño; si no, termina.

## Enemigos entre los que busca el siguiente al rebotar.
@export_range(1, 64, 1) var bounce_candidates: int = 8

var _finder: TargetFinder
var _bounces_left: int = 0


func _launched() -> void:
	if _finder == null:
		_finder = TargetFinder.new(weapon.target_mask)
	_bounces_left = _stats().bounces


func _impact(hurtbox: HurtboxComponent, point: Vector3) -> void:
	strike(hurtbox)
	ignore(hurtbox)
	if _bounces_left <= 0:
		_finish()
		return
	var next := _next_target(point)
	if next == null:
		_finish()
		return
	_bounces_left -= 1
	redirect(TargetFinder.aim_point(next) - point)
	renew_life()


## Rebotes que le quedan.
func bounces_left() -> int:
	return _bounces_left


func _next_target(point: Vector3) -> HurtboxComponent:
	var space := get_world_3d().direct_space_state
	for target: Node3D in _finder.nearest(space, point, _stats().bounce_range, bounce_candidates):
		var hurtbox := target as HurtboxComponent
		if hurtbox and not ignores(hurtbox):
			return hurtbox
	return null


func _stats() -> DaggerStats:
	return weapon.stats.get_resolved(DaggerStats) as DaggerStats
