class_name BodyCrouch
extends Node
## Agacha el modelo (solo visual) mientras el estado de movimiento es uno de
## [member crouch_states] (el slide), y lo levanta al salir. Ni la colisión ni la hurtbox
## cambian aquí. Mantiene los pies en el suelo: el modelo tiene el pivote en su centro.

@export var machine: StateMachine
## Modelo que se agacha.
@export var visual: Node3D
## Estados en los que el modelo va agachado.
@export var crouch_states: Array[Node] = []
## Altura del modelo agachado respecto a la normal.
@export_range(0.2, 1.0, 0.05) var crouch_scale: float = 0.55
## Rapidez con la que se agacha y se levanta.
@export_range(1.0, 60.0, 0.5, "suffix:1/s") var speed: float = 18.0

var _rest_scale: Vector3
var _rest_position: Vector3
var _target: float = 1.0


func _ready() -> void:
	_rest_scale = visual.scale
	_rest_position = visual.position
	machine.state_changed.connect(_on_state_changed)


func _physics_process(delta: float) -> void:
	var current := visual.scale.y / _rest_scale.y
	# Suavizado exponencial: igual de rápido a cualquier tasa de ticks.
	var next := lerpf(current, _target, 1.0 - exp(-speed * delta))
	visual.scale.y = _rest_scale.y * next
	visual.position.y = _rest_position.y * next


## Proporción de altura objetivo del modelo (1 = de pie).
func get_target() -> float:
	return _target


func _on_state_changed(_previous: State, current: State) -> void:
	_target = crouch_scale if crouch_states.has(current) else 1.0
