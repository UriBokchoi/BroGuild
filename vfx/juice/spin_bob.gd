class_name SpinBob
extends Node
## Hace girar y flotar arriba y abajo un modelo (los recogibles especiales, que son pocos; los que
## salen a cientos lo hacen en su shader). Solo visual.

## Modelo que gira y flota.
@export var target: Node3D
## Velocidad de giro.
@export_range(0.0, 20.0, 0.1, "suffix:rad/s") var spin_speed: float = 2.0
## Cuánto sube y baja.
@export_range(0.0, 1.0, 0.01, "suffix:m") var bob_height: float = 0.08
## Subidas y bajadas por segundo.
@export_range(0.0, 10.0, 0.1, "suffix:Hz") var bob_rate: float = 1.2

var _rest_y: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_rest_y = target.position.y


func _process(delta: float) -> void:
	_time += delta
	target.rotation.y = wrapf(target.rotation.y + spin_speed * delta, 0.0, TAU)
	target.position.y = _rest_y + sin(_time * TAU * bob_rate) * bob_height
