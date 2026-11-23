class_name BodyBob
extends Node
## Balanceo al andar: mientras el personaje va por el suelo en uno de [member walk_states], su cuerpo
## sube y baja un poco a cada paso y se mece de lado a lado. Cuanto más rápido va, más alto rebota y
## más pasos da, para que correr se sienta como correr. Con rapidez por encima de la carrera normal
## (mejoras), rebota más, hasta [member max_ratio]. Al pararse vuelve a su sitio suavemente. Solo
## visual: mueve [member parts] (las partes del modelo, no el modelo entero, que ya lo agachan,
## giran y voltean otros nodos). Avisa de cada paso que toca el suelo ([signal stepped]).

## Un pie tocó el suelo (abajo del rebote), con [param ratio] la rapidez respecto a la carrera.
signal stepped(ratio: float)

## Quien anda.
@export var body: CharacterBody3D
## Stats del personaje: su rapidez de carrera ([MovementData]) marca el ritmo normal.
@export var stats: StatsComponent
@export var machine: StateMachine
## Estados en los que anda (el suelo; no el slide).
@export var walk_states: Array[Node] = []
## Partes del modelo que se mueven (cuerpo y anclajes).
@export var parts: Array[Node3D] = []
## Rapidez mínima para balancearse.
@export_range(0.0, 5.0, 0.05, "suffix:m/s") var min_speed: float = 0.5
## Altura del rebote a la rapidez de carrera.
@export_range(0.0, 0.5, 0.005, "suffix:m") var bob_height: float = 0.08
## Mecida de lado a lado a la rapidez de carrera.
@export_range(0.0, 20.0, 0.1, "radians_as_degrees") var sway: float = 0.05
## Pasos por segundo andando despacio y a la rapidez de carrera.
@export_range(0.1, 10.0, 0.05, "suffix:1/s") var slow_steps: float = 1.8
@export_range(0.1, 10.0, 0.05, "suffix:1/s") var run_steps: float = 3.2
## Rapidez respecto a la carrera a partir de la cual ya no rebota más.
@export_range(1.0, 3.0, 0.05) var max_ratio: float = 1.5
## Rapidez con la que vuelve a su sitio al pararse.
@export_range(1.0, 60.0, 0.5, "suffix:1/s") var settle_speed: float = 12.0

var _rest: Dictionary[Node3D, Transform3D] = {}
var _walking: bool = false
var _phase: float = 0.0
var _offset: float = 0.0
var _roll: float = 0.0


func _ready() -> void:
	for part: Node3D in parts:
		_rest[part] = part.transform
	machine.state_changed.connect(_on_state_changed)


func _physics_process(delta: float) -> void:
	var ratio := speed_ratio()
	if _walking and body.is_on_floor() and ratio > 0.0:
		var steps := lerpf(slow_steps, run_steps, minf(ratio, 1.0))
		var previous := _phase
		# Medio ciclo de seno por paso: el rebote toca abajo en cada múltiplo de PI.
		_phase += PI * steps * delta
		if floorf(_phase / PI) > floorf(previous / PI):
			stepped.emit(ratio)
		var strength := minf(ratio, max_ratio)
		_offset = bob_height * strength * absf(sin(_phase))
		_roll = sway * strength * sin(_phase)
	else:
		var weight := 1.0 - exp(-settle_speed * delta)
		_offset = lerpf(_offset, 0.0, weight)
		_roll = lerpf(_roll, 0.0, weight)
		if absf(_offset) < 0.0005 and absf(_roll) < 0.0005:
			_offset = 0.0
			_roll = 0.0
			_phase = 0.0
	_apply()


## Rapidez horizontal respecto a la de carrera (0 si va más lento que [member min_speed]).
func speed_ratio() -> float:
	var horizontal := Vector2(body.velocity.x, body.velocity.z).length()
	if horizontal < min_speed:
		return 0.0
	var move := stats.get_resolved(MovementData) as MovementData
	return horizontal / move.run_speed if move.run_speed > 0.0 else 0.0


## Cuánto sube ahora el cuerpo sobre su sitio.
func get_offset() -> float:
	return _offset


func _apply() -> void:
	var lift := Transform3D(Basis(Vector3.FORWARD, _roll), Vector3.UP * _offset)
	for part: Node3D in parts:
		part.transform = lift * _rest[part]


func _on_state_changed(_previous: State, current: State) -> void:
	_walking = walk_states.has(current)
