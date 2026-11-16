class_name StaffOrb
extends Projectile
## Orbe del bastón de mago: al tocar a un enemigo o una pared explota y hace el daño del arma a
## todos los enemigos dentro del radio de explosión (cada uno con su tirada de crítico). La
## explosión se ve un momento y después vuelve al pool.

## Orbe que vuela.
@export var orb: Node3D
## Esfera de la explosión (radio 1, con el shader [code]staff_blast.gdshader[/code]).
@export var blast: GeometryInstance3D
## Segundos que se ve la explosión.
@export_range(0.05, 2.0, 0.01, "suffix:s") var blast_time: float = 0.3
## Enemigos que puede alcanzar una explosión como mucho.
@export_range(1, 256, 1) var max_targets: int = 64

var _finder: TargetFinder
var _blast_radius: float = 0.0
var _blast_age: float = -1.0


func _process(delta: float) -> void:
	_blast_age += delta
	var progress := clampf(_blast_age / blast_time, 0.0, 1.0)
	blast.scale = Vector3.ONE * _blast_radius * (0.35 + 0.65 * (1.0 - pow(1.0 - progress, 3.0)))
	blast.set_instance_shader_parameter(&"progress", progress)
	if progress >= 1.0:
		set_process(false)
		blast.visible = false
		_finish()


func _launched() -> void:
	if _finder == null:
		_finder = TargetFinder.new(weapon.target_mask)
	orb.visible = true
	blast.visible = false


func _impact(_hurtbox: HurtboxComponent, point: Vector3) -> void:
	_explode(point)


func _impact_world(point: Vector3) -> void:
	_explode(point)


## Radio de la explosión ahora: el de sus stats por el área del arma.
func explosion_radius() -> float:
	return (weapon.stats.get_resolved(StaffStats) as StaffStats).explosion_radius * weapon.area_scale()


func _explode(point: Vector3) -> void:
	set_physics_process(false)
	_blast_radius = explosion_radius()
	var space := get_world_3d().direct_space_state
	for target: Node3D in _finder.nearest(space, point, _blast_radius, max_targets):
		var hurtbox := target as HurtboxComponent
		if hurtbox:
			strike(hurtbox)
	orb.visible = false
	blast.visible = true
	_blast_age = 0.0
	set_process(true)
