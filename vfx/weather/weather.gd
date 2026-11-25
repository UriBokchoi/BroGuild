class_name Weather
extends Node3D
## Clima de un mapa (hojas de otoño, nieve): partículas que caen alrededor del jugador. Sigue a
## target en horizontal; las partículas, en coordenadas del mundo, no se mueven con él.

## A quién sigue (lo pone el mapa: LevelMap.followers).
@export var target: Node3D


func _ready() -> void:
	# Sigue la posición ya interpolada del jugador en _process (como las cámaras).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(_delta: float) -> void:
	if target:
		var at := target.global_position
		global_position = Vector3(at.x, 0.0, at.z)
