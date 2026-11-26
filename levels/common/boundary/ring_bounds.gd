class_name RingBounds
extends StaticBody3D
## Las paredes de choque de un mapa redondo (la arena final): tramos rectos alrededor de un círculo,
## con la cara de dentro a radius del centro. Se hacen al estar listas; lo que se ve es MapBoundary.

## Cuánto se solapan los tramos, para que no quede ninguna rendija entre ellos.
const OVERLAP := 1.05

## Distancia del centro a la cara de dentro de las paredes.
@export_range(1.0, 500.0, 0.5, "suffix:m") var radius: float = 1.0
## En cuántos tramos se hace el círculo.
@export_range(8, 256, 1) var segments: int = 32
@export_range(1.0, 100.0, 0.5, "suffix:m") var height: float = 30.0
@export_range(0.5, 20.0, 0.5, "suffix:m") var thickness: float = 2.0


func _ready() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0 * (radius + thickness) * tan(PI / segments) * OVERLAP, height, thickness)
	for index: int in segments:
		var spot := Vector2.from_angle(TAU * index / segments) * (radius + thickness / 2.0)
		var wall := CollisionShape3D.new()
		wall.shape = shape
		wall.position = Vector3(spot.x, height / 2.0, spot.y)
		wall.rotation.y = atan2(spot.x, spot.y)
		add_child(wall)
