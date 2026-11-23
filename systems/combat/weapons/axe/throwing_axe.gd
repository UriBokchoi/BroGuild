class_name ThrowingAxe
extends Projectile
## Hacha arrojadiza: sale girando hacia su objetivo y atraviesa a todos los enemigos que pilla (a cada
## uno, una vez por tramo): los que cruza y los que pasan a menos de [member edge_radius] (por el área
## del arma) de ella, que el hacha gira tumbada y corta a lo ancho. Al pasar
## [member outward_share] de su vida, o si choca con el mundo, da la vuelta: persigue a quien la lanzó,
## vuelve a golpear a lo que pille y atraviesa el mundo. Termina al llegar a sus manos (o, por si no
## puede volver, al acabar su vida de vuelta). Se ve más grande con el área.

## Lo que gira (el hacha, tumbada: gira en horizontal, como un aspa).
@export var spin: Node3D
## Vueltas por segundo.
@export_range(0.0, 20.0, 0.1) var spins_per_second: float = 3.0
## Tamaño del modelo (antes del área, con la que también crece).
@export_range(0.1, 5.0, 0.05) var model_scale: float = 1.7
## Distancia a quien la lanzó a la que la recoge.
@export_range(0.1, 5.0, 0.05, "suffix:m") var catch_distance: float = 1.2
## Parte de su vida que pasa yendo antes de volver.
@export_range(0.1, 0.9, 0.05) var outward_share: float = 0.5
## Alcance de su filo alrededor (antes del área): corta a lo que pasa así de cerca.
@export_range(0.0, 5.0, 0.05, "suffix:m") var edge_radius: float = 1.2
## Enemigos que mira su filo en cada tick como mucho.
@export_range(1, 128, 1) var max_edge_targets: int = 16

var _edge_finder: TargetFinder

var _returning: bool = false
var _outward_left: float = 0.0
## Capas que detiene a la ida (las de la escena); a la vuelta, sin el mundo.
var _outward_mask: int = 0


func _ready() -> void:
	_outward_mask = hit_mask
	super()


func _process(delta: float) -> void:
	spin.rotate_object_local(Vector3.UP, -TAU * spins_per_second * delta)


func _physics_process(delta: float) -> void:
	if _returning:
		var to_hand := weapon.aim_origin() - global_position
		if to_hand.length() <= catch_distance:
			_finish()
			return
		redirect(to_hand)
	else:
		_outward_left -= delta
		if _outward_left <= 0.0:
			turn_back()
	super(delta)
	if is_physics_processing():
		_cut_around()


## ¿Ya está volviendo?
func is_returning() -> bool:
	return _returning


## Da la vuelta hacia quien la lanzó: a partir de ahora puede volver a golpear a los de la ida y
## atraviesa el mundo.
func turn_back() -> void:
	if _returning:
		return
	_returning = true
	hit_mask = _outward_mask & ~PhysicsLayers.mask(PhysicsLayers.WORLD)
	clear_ignored()
	renew_life()


## Golpea a lo que pasa cerca del filo y aún no ha recibido en este tramo.
func _cut_around() -> void:
	var radius := edge_radius * weapon.area_scale()
	if radius <= 0.0:
		return
	var space := get_world_3d().direct_space_state
	for found: Node3D in _edge_finder.nearest(space, global_position, radius, max_edge_targets):
		var hurtbox := found as HurtboxComponent
		if hurtbox and not ignores(hurtbox):
			strike(hurtbox)
			ignore(hurtbox)


func _launched() -> void:
	if _edge_finder == null:
		_edge_finder = TargetFinder.new(weapon.target_mask)
		_edge_finder.max_candidates = max_edge_targets
	spin.scale = Vector3.ONE * model_scale * weapon.area_scale()
	_returning = false
	hit_mask = _outward_mask
	_outward_left = weapon.duration() * outward_share
	set_process(true)


func _impact(hurtbox: HurtboxComponent, _point: Vector3) -> void:
	strike(hurtbox)
	ignore(hurtbox)


func _impact_world(_point: Vector3) -> void:
	turn_back()
