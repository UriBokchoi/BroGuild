class_name SlamAttack
extends BossAttack
## Porrazo en área (el del Trolleador Cara): se planta y levanta el arma mientras dos aros en el suelo
## avisan. Uno marca hasta dónde llega el golpe; el otro se abre desde sus pies y, cuando llega al
## borde, cae el porrazo. Entonces suelta una [Shockwave] rápida, que daña su contacto ×
## [member damage_factor] a todo lo que pille dentro. Se esquiva saliendo del aro a tiempo (o
## saltando justo cuando cae). Después se queda un momento quieto, con el arma abajo.

enum Phase { WINDUP, SWING, RECOVERY }

## Segundos levantando el arma (lo que dura el aviso).
@export_range(0.1, 5.0, 0.05, "suffix:s") var windup: float = 1.2
## Segundos que tarda el arma en caer.
@export_range(0.02, 1.0, 0.01, "suffix:s") var swing_time: float = 0.12
## Segundos quieto tras el golpe.
@export_range(0.0, 5.0, 0.05, "suffix:s") var recovery: float = 0.8
## Daño del golpe: su daño al tocar por esto.
@export_range(0.0, 20.0, 0.05) var damage_factor: float = 1.6
## Alto del modelo al golpear (1 = normal): se agacha con el porrazo.
@export_range(0.1, 1.0, 0.05) var impact_squash: float = 0.85
## La onda del golpe (su radio es el del aro).
@export var shockwave: Shockwave
## Aro fijo que marca hasta dónde llega (un plano de 2 × 2 con [code]ground_ring.gdshader[/code]).
@export var edge_marker: GeometryInstance3D
## Aro que se abre desde sus pies hasta el borde mientras levanta el arma.
@export var charge_marker: GeometryInstance3D
## Brazo que levanta (gira en x desde su postura de reposo). Vacío: no mueve ninguno.
@export var arm: Node3D
## Giro del brazo arriba, a punto de golpear, y al acabar de caer.
@export_range(-180.0, 180.0, 1.0, "radians_as_degrees") var raised_angle: float = -2.6
@export_range(-180.0, 180.0, 1.0, "radians_as_degrees") var swing_angle: float = 0.4

var _phase: Phase = Phase.WINDUP
var _left: float = 0.0
var _rest_angle: float = 0.0


func _ready() -> void:
	if arm:
		_rest_angle = arm.rotation.x
	_hide_markers()


func begin(_target: Vector3) -> void:
	var feet := boss.global_position
	for marker: GeometryInstance3D in [edge_marker, charge_marker]:
		marker.global_position = feet
		marker.scale = Vector3.ONE * shockwave.radius
		marker.visible = true
	charge_marker.set_instance_shader_parameter(&"progress", 0.0)
	_phase = Phase.WINDUP
	_left = windup


func step(delta: float, target: Vector3) -> bool:
	_left -= delta
	boss.move_flat(Vector3.ZERO)
	match _phase:
		Phase.WINDUP:
			boss.face_toward(target, delta)
			var progress := 1.0 - maxf(_left, 0.0) / windup
			charge_marker.set_instance_shader_parameter(&"progress", progress)
			_pose(lerpf(_rest_angle, raised_angle, ease(progress, 0.4)))
			if _left <= 0.0:
				_phase = Phase.SWING
				_left = swing_time
		Phase.SWING:
			var progress := 1.0 - maxf(_left, 0.0) / swing_time
			_pose(lerpf(raised_angle, swing_angle, progress))
			if _left <= 0.0:
				_impact()
		Phase.RECOVERY:
			var progress := 1.0 - maxf(_left, 0.0) / maxf(recovery, 0.001)
			_pose(lerpf(swing_angle, _rest_angle, progress))
			boss.squash(lerpf(impact_squash, 1.0, progress))
			if _left <= 0.0:
				return true
	return false


func cancel() -> void:
	_hide_markers()
	shockwave.stop()
	_pose(_rest_angle)
	boss.squash(1.0)


## Fase en la que está (para los tests).
func get_phase() -> Phase:
	return _phase


func _impact() -> void:
	_hide_markers()
	boss.squash(impact_squash)
	shockwave.start(boss.global_position, boss.get_contact_damage() * damage_factor)
	_phase = Phase.RECOVERY
	_left = recovery


func _pose(angle: float) -> void:
	if arm:
		arm.rotation.x = angle


func _hide_markers() -> void:
	edge_marker.visible = false
	charge_marker.visible = false
