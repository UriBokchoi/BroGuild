class_name StoneStatue
extends Node3D
## Estatuas de piedra hechas con modelos del juego (los trolls de fuera del Brosque, que se quedaron
## de piedra al amanecer): al entrar en el árbol pinta todas las mallas de [member statues] con
## [member material]. Lo que no esté en [member statues] (el musgo, la olla) conserva el suyo. Solo
## decorado: sin colisión ni lógica.

## Material de piedra.
@export var material: Material
## Modelos que se vuelven de piedra (con todo lo que llevan dentro).
@export var statues: Array[Node3D] = []


func _ready() -> void:
	for statue: Node3D in statues:
		_petrify(statue)


## Mallas que pinta (para los tests).
func meshes() -> Array[GeometryInstance3D]:
	var found: Array[GeometryInstance3D] = []
	for statue: Node3D in statues:
		_collect(statue, found)
	return found


func _petrify(node: Node) -> void:
	var found: Array[GeometryInstance3D] = []
	_collect(node, found)
	for mesh: GeometryInstance3D in found:
		mesh.material_override = material


static func _collect(node: Node, found: Array[GeometryInstance3D]) -> void:
	var geometry := node as GeometryInstance3D
	if geometry:
		found.append(geometry)
	for child: Node in node.get_children():
		_collect(child, found)
