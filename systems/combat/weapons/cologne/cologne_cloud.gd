class_name CologneCloud
extends Weapon
## Nube de colonia (un spray corporal, GDD §6): un aura alrededor de quien la lleva. Cuando hay algún
## enemigo dentro, suelta un pulso que daña a todos los de dentro y los empuja un poco hacia fuera.
## Los proyectiles extra son más pulsos seguidos (separados por
## [member WeaponStats.burst_interval]). Su radio es su alcance por el área; la nube que se ve
## ([member cloud]) crece con él y se aviva en cada pulso. No necesita ver a los enemigos: la colonia
## llega a todas partes.

## Nube que se ve: una esfera de radio 1 con [code]cologne_cloud.gdshader[/code] (su parámetro de
## instancia [code]pulse[/code] la aviva).
@export var cloud: GeometryInstance3D
## Enemigos que alcanza un pulso como mucho.
@export_range(1, 512, 1) var max_targets: int = 128
## Segundos que tarda en apagarse el brillo de un pulso.
@export_range(0.05, 2.0, 0.01, "suffix:s") var pulse_fade: float = 0.35
## Alto de la nube respecto a su ancho (achatada, como una nube a la altura del cuerpo).
@export_range(0.1, 1.0, 0.05) var height_ratio: float = 0.6

var _area_finder: TargetFinder
var _glow: float = 0.0


func _ready() -> void:
	super()
	_area_finder = TargetFinder.new(target_mask)
	_area_finder.max_candidates = max_targets


func _process(delta: float) -> void:
	var radius := reach()
	cloud.scale = Vector3(radius, radius * height_ratio, radius)
	_glow = maxf(_glow - delta / pulse_fade, 0.0)
	cloud.set_instance_shader_parameter(&"pulse", _glow)


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
