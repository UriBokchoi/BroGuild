class_name WingFlap
extends Node
## Aletea: gira las alas de un lado a otro sin parar (solo se ve; un murciélago, un pájaro).

## Las alas: la izquierda y la derecha, que giran al revés una de la otra.
@export var left: Node3D
@export var right: Node3D
## Aleteos por segundo y cuánto giran (a cada lado de su postura).
@export_range(0.1, 20.0, 0.1, "suffix:Hz") var speed: float = 1.0
@export_range(0.0, 90.0, 1.0, "radians_as_degrees") var angle: float = 0.0

var _time: float = 0.0
var _left_rest: float = 0.0
var _right_rest: float = 0.0


func _ready() -> void:
	_left_rest = left.rotation.z
	_right_rest = right.rotation.z


func _process(delta: float) -> void:
	_time += delta
	var swing := sin(_time * TAU * speed) * angle
	left.rotation.z = _left_rest + swing
	right.rotation.z = _right_rest - swing
