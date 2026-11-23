class_name BossAttack
extends Node
## Un ataque de un [Boss] (un nodo hijo suyo). El jefe lo elige al azar según [member weight] entre
## los que puede hacer, lo empieza con [method begin] y lo avanza con [method step] en cada tick de
## física hasta que termina; mientras, no persigue: el ataque mueve el cuerpo. Si el jefe muere o se
## retira, [method cancel] quita lo que haya dejado a la vista. Un ataque nuevo es un script que
## hereda de este, con sus números en [code]@export[/code].

## Peso al elegir el siguiente ataque.
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
## Solo lo hace con rabia.
@export var enraged_only: bool = false

## Quien lo hace (lo pone el jefe al prepararse).
var boss: Boss


## Empieza el ataque contra [param target] (donde está el objetivo).
func begin(_target: Vector3) -> void:
	pass


## Avanza [param delta] segundos; [param target] es donde está el objetivo ahora. Devuelve
## [code]true[/code] al terminar.
func step(_delta: float, _target: Vector3) -> bool:
	return true


## Lo corta (el jefe murió o se retiró): quita sus avisos y deja el modelo normal.
func cancel() -> void:
	pass


## Lo que va de [param from] a [param to] en el suelo (sin la altura).
static func flat(from: Vector3, to: Vector3) -> Vector3:
	return Vector3(to.x - from.x, 0.0, to.z - from.z)
