class_name CologneCloud
extends Weapon
## Nube de colonia (GDD §6): un aura alrededor de quien la lleva. Si hay algún enemigo dentro, suelta
## un pulso que daña a todos y los aparta un poco. Sus proyectiles extra son más pulsos. No necesita
## ver a los enemigos: la colonia llega a todas partes.
##
## Su alcance se dibuja en el suelo, como en Megabonk: un aro que gira despacio bajo el jugador.

## Dibujo del alcance: un plano de 2 × 2 (radio 1) con [code]cologne_ring.gdshader[/code] (su
## parámetro de instancia [code]pulse[/code] lo aviva). Va suelto en el mundo
## ([code]top_level[/code]): se coloca solo en el suelo bajo quien la lleva.
@export var ring: GeometryInstance3D
## Enemigos que alcanza un pulso como mucho.
@export_range(1, 512, 1) var max_targets: int = 128
## Segundos que tarda en apagarse el brillo de un pulso.
@export_range(0.05, 2.0, 0.01, "suffix:s") var pulse_fade: float = 0.35
## Vueltas del aro: grados por segundo.
@export_range(0.0, 180.0, 1.0, "suffix:°/s") var spin_speed: float = 12.0
## Qué cuenta como suelo para poner el aro, cuánto mira hacia abajo y a qué altura lo deja (un pelo
## por encima, para que no parpadee con el suelo).
@export_flags_3d_physics var ground_mask: int = 1
@export_range(0.5, 50.0, 0.5, "suffix:m") var ground_probe: float = 8.0
@export_range(0.0, 0.5, 0.01, "suffix:m") var ground_lift: float = 0.04

var _area_finder: TargetFinder
var _glow: float = 0.0
var _spin: float = 0.0


func _ready() -> void:
	super()
	_area_finder = TargetFinder.new(target_mask)
	_area_finder.max_candidates = max_targets
	ring.top_level = true


func _process(delta: float) -> void:
	_spin = wrapf(_spin + deg_to_rad(spin_speed) * delta, 0.0, TAU)
	var radius := reach()
	ring.global_transform = Transform3D(
		Basis(Vector3.UP, _spin).scaled(Vector3(radius, 1.0, radius)), _ground_below() + Vector3.UP * ground_lift
	)
	_glow = maxf(_glow - delta / pulse_fade, 0.0)
	ring.set_instance_shader_parameter(&"pulse", _glow)


## Radio del aura: su alcance por el área.
func reach() -> float:
	return _weapon.reach * area_scale()


## Brillo del último pulso que queda (1 = recién soltado, 0 = apagado).
func glow() -> float:
	return _glow


func _fire(_target: Node3D, _index: int) -> void:
	var center := aim_origin()
	var space := get_world_3d().direct_space_state
	for found: Node3D in _area_finder.nearest(space, center, reach(), max_targets):
		var hurtbox := found as HurtboxComponent
		if hurtbox == null:
			continue
		var push := DamageCalc.push(center, hurtbox.get_center(), knockback())
		hurtbox.receive(DamageCalc.attack(damage(), offense(), rng, self, push))
	_glow = 1.0


func _disarmed() -> void:
	_glow = 0.0


## El suelo bajo quien la lleva (al saltar, el aro se queda abajo). Sin suelo cerca, a sus pies.
func _ground_below() -> Vector3:
	var from := aim_origin()
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * ground_probe, ground_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return global_position
	var ground: Vector3 = hit["position"]
	return ground
