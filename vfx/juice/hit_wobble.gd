class_name HitWobble
extends Node3D
## Bamboleo al recibir un golpe: inclina [member target] alejándolo de quien golpea y lo devuelve a
## su sitio con un muelle. Escucha la vida (juice desacoplado); no cambia el gameplay. Va en la
## raíz de la entidad, sin girar: mide las direcciones con su propia orientación.

@export var health: HealthComponent
## Nodo que se inclina (el modelo, con el pivote en los pies).
@export var target: Node3D
## Velocidad de giro que da cada golpe.
@export_range(0.0, 1000.0, 1.0, "suffix:°/s") var kick: float = 220.0
## Multiplica el golpe si es crítico.
@export_range(1.0, 5.0, 0.1) var critical_multiplier: float = 1.8
## Fuerza con la que vuelve a su sitio.
@export_range(1.0, 1000.0, 1.0) var stiffness: float = 180.0
## Frenado del muelle.
@export_range(0.0, 100.0, 0.5) var damping: float = 9.0
## Inclinación máxima.
@export_range(1.0, 90.0, 1.0, "suffix:°") var max_tilt: float = 35.0

## Inclinación (x: giro en X, y: giro en Z) y su velocidad, en radianes.
var _tilt: Vector2 = Vector2.ZERO
var _spin: Vector2 = Vector2.ZERO


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	target.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(delta: float) -> void:
	_spin += (-stiffness * _tilt - damping * _spin) * delta
	_tilt += _spin * delta
	_tilt = _tilt.limit_length(deg_to_rad(max_tilt))
	target.rotation = Vector3(_tilt.x, target.rotation.y, _tilt.y)


## Inclinación actual en grados (para tests y depuración).
func get_tilt_degrees() -> float:
	return rad_to_deg(_tilt.length())


func _on_damaged(_amount: float, info: DamageInfo) -> void:
	var away := Vector3.FORWARD
	var source := info.source as Node3D
	if source:
		away = global_position - source.global_position
	away = global_basis.inverse() * away
	away.y = 0.0
	if away.is_zero_approx():
		away = Vector3.FORWARD
	away = away.normalized()
	var strength := deg_to_rad(kick) * (critical_multiplier if info.critical else 1.0)
	# Girar en X inclina la cabeza hacia +Z; girar en Z, hacia −X.
	_spin += Vector2(away.z, -away.x) * strength
