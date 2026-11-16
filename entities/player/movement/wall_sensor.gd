class_name WallSensor
extends Node
## Busca paredes junto al cuerpo con rayos horizontales a su alrededor, para el salto en pared.
## No hace falta estar empujando la pared. Solo cuentan superficies casi verticales de las capas
## de [member collision_mask] (el mundo).

@export var body: CharacterBody3D
## Capas que cuentan como pared.
@export_flags_3d_physics var collision_mask: int = 1
## Altura de los rayos sobre los pies (el centro del cuerpo).
@export_range(0.0, 3.0, 0.05, "suffix:m") var height: float = 0.9
## Rayos alrededor del cuerpo; más rayos, menos huecos entre direcciones.
@export_range(4, 32, 1) var ray_count: int = 12
## Inclinación máxima de la normal (su componente vertical) para contar como pared.
@export_range(0.0, 1.0, 0.05) var max_normal_y: float = 0.3


## Normal (horizontal) de la pared más cercana a menos de [param reach] metros del centro del
## cuerpo; cero si no hay ninguna.
func find_wall(reach: float) -> Vector3:
	var space := body.get_world_3d().direct_space_state
	var origin := body.global_position + Vector3.UP * height
	var closest := INF
	var wall := Vector3.ZERO
	for i: int in ray_count:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / ray_count)
		var query := PhysicsRayQueryParameters3D.create(
			origin, origin + direction * reach, collision_mask, [body.get_rid()]
		)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var normal: Vector3 = hit["normal"]
		var point: Vector3 = hit["position"]
		var distance := origin.distance_to(point)
		if absf(normal.y) <= max_normal_y and distance < closest:
			closest = distance
			wall = Vector3(normal.x, 0.0, normal.z).normalized()
	return wall
