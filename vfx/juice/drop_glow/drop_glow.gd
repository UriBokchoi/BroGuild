class_name DropGlow
extends Node3D
## Lo que hace llamativo a un recogible especial (los power-ups): una columna de luz corta y un aro
## que late en el suelo, los dos de su [member color], para verlo desde lejos entre la horda. Va en
## la escena del recogible ([Pickup]) y se pone en el suelo, bajo lo que flota. Solo visual.

## Color de la luz y del aro.
@export var color: Color = Color.WHITE
## Columna de luz ([code]light_beam.gdshader[/code], material propio de la escena).
@export var beam: GeometryInstance3D
## Aro del suelo ([code]ground_ring.gdshader[/code], material propio de la escena).
@export var ring: GeometryInstance3D


func _ready() -> void:
	var pickup := get_parent() as Pickup
	if pickup:
		position.y = -pickup.float_height
	for mesh: GeometryInstance3D in [beam, ring]:
		(mesh.material_override as ShaderMaterial).set_shader_parameter(&"color", color)
