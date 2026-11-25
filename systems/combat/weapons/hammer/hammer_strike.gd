class_name HammerStrike
extends Node3D
## Un golpe del martillo de guerra ([WarHammer]): un aro en el suelo avisa dónde va a caer mientras
## el martillo baja del cielo; al tocar el suelo daña a todas las hurtbox enemigas dentro de su radio
## (empujándolas desde el centro), el aro destella y el martillo se encoge y desaparece. Vive en el
## mundo ([code]top_level[/code]) y vuelve al pool del arma al terminar ([signal finished]).

## Terminó (vuelve al pool).
signal finished

enum Phase { FALLING, LINGER }

## El martillo que cae (su cabeza toca el suelo a la altura 0 de su nodo).
@export var hammer: Node3D
## Aro del suelo (un plano de 2 × 2 con [code]ground_ring.gdshader[/code]; se escala al radio).
@export var marker: GeometryInstance3D
## Segundos que tarda en caer (lo que dura el aviso).
@export_range(0.05, 2.0, 0.01, "suffix:s") var fall_time: float = 0.35
## Altura desde la que cae.
@export_range(1.0, 30.0, 0.5, "suffix:m") var fall_height: float = 7.0
## Segundos que se queda tras el golpe, encogiendo.
@export_range(0.05, 2.0, 0.01, "suffix:s") var linger: float = 0.3
## Enemigos que alcanza un golpe como mucho.
@export_range(1, 256, 1) var max_targets: int = 64

var _weapon: WarHammer
var _finder: TargetFinder
var _rng: RandomNumberGenerator
var _phase: Phase = Phase.FALLING
var _elapsed: float = 0.0
var _radius: float = 0.0


func _ready() -> void:
	top_level = true
	_rng = Rng.stream(Rng.Stream.COMBAT)
	_stop()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	match _phase:
		Phase.FALLING:
			var progress := minf(_elapsed / fall_time, 1.0)
			hammer.position.y = fall_height * (1.0 - progress * progress)
			marker.set_instance_shader_parameter(&"progress", progress)
			if progress >= 1.0:
				_impact()
		Phase.LINGER:
			var progress := minf(_elapsed / linger, 1.0)
			hammer.scale = Vector3.ONE * (1.0 - progress)
			marker.set_instance_shader_parameter(&"fade", 1.0 - progress)
			if progress >= 1.0:
				_stop()
				finished.emit()


## Cae en [param at] (en el suelo) con las stats de [param from]: su daño, su empuje y su radio.
func drop(from: WarHammer, at: Vector3) -> void:
	_weapon = from
	if _finder == null:
		_finder = TargetFinder.new(from.target_mask)
		_finder.max_candidates = max_targets
	global_position = at
	_radius = from.impact_radius()
	marker.scale = Vector3.ONE * _radius
	marker.set_instance_shader_parameter(&"progress", 0.0)
	marker.set_instance_shader_parameter(&"fade", 1.0)
	hammer.position.y = fall_height
	hammer.scale = Vector3.ONE
	_phase = Phase.FALLING
	_elapsed = 0.0
	visible = true
	set_physics_process(true)
	reset_physics_interpolation()


## ¿Está cayendo o encogiendo?
func is_active() -> bool:
	return is_physics_processing()


## Radio de este golpe.
func radius() -> float:
	return _radius


## Lo quita antes de tiempo (su arma dejó de atacar).
func recall() -> void:
	if is_active():
		_stop()
		finished.emit()


func _impact() -> void:
	var space := get_world_3d().direct_space_state
	for found: Node3D in _finder.nearest(space, global_position, _radius, max_targets):
		var hurtbox := found as HurtboxComponent
		if hurtbox == null:
			continue
		var push := DamageCalc.push(global_position, hurtbox.get_center(), _weapon.knockback())
		hurtbox.receive(DamageCalc.attack(_weapon.damage(), _weapon.offense(), _rng, self, push))
	marker.set_instance_shader_parameter(&"progress", 1.0)
	_phase = Phase.LINGER
	_elapsed = 0.0


func _stop() -> void:
	set_physics_process(false)
	visible = false
