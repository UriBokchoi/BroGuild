class_name InteractHint
extends Node
## Aviso sutil de que algo se puede usar con «interactuar»: encima de las mallas de [member visual]
## ([code]material_overlay[/code]) pone un destello que lo recorre de vez en cuando
## ([member idle_material]) y, si es el que se usaría ahora (el más cercano al jugador), un borde de
## luz más marcado ([member focus_material]). Desactivado su [member interactable], no se ve. Solo
## visual: escucha las señales del [Interactable].

@export var interactable: Interactable
## Modelo que destella (sus mallas, también las de dentro; los textos no).
@export var visual: Node3D
## Destello de siempre.
@export var idle_material: Material
## Destello del que se usaría ahora.
@export var focus_material: Material

var _meshes: Array[GeometryInstance3D] = []


func _ready() -> void:
	# Solo mallas: un texto (Label3D) con el destello encima se vería como un rectángulo.
	for mesh: Node in visual.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(mesh as GeometryInstance3D)
	var own := visual as MeshInstance3D
	if own:
		_meshes.append(own)
	interactable.focus_changed.connect(_refresh.unbind(1))
	interactable.enabled_changed.connect(_refresh.unbind(1))
	_refresh()


## Material que lleva ahora encima (para tests), o [code]null[/code].
func get_overlay() -> Material:
	return null if _meshes.is_empty() else _meshes[0].material_overlay


func _refresh() -> void:
	var material: Material = null
	if interactable.enabled:
		material = focus_material if interactable.is_focused() else idle_material
	for mesh: GeometryInstance3D in _meshes:
		mesh.material_overlay = material
