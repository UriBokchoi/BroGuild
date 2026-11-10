class_name LedgeSensor
extends Node
## Busca delante del cuerpo un borde al que subir (para el mantle): una pared al alcance cuya
## parte de arriba quede entre una altura mínima y una máxima sobre los pies, con sitio encima
## para el cuerpo. Solo cuentan las capas de [member collision_mask] (el mundo).

## Borde encontrado: dónde quedan los pies al subir, hacia dónde se sube y su altura.
class Ledge:
	var target: Vector3
	var direction: Vector3
	var height: float


@export var body: CharacterBody3D
## Forma del cuerpo (una cápsula), para comprobar que cabe encima del borde.
@export var body_shape: CollisionShape3D
## Capas que cuentan como borde.
@export_flags_3d_physics var collision_mask: int = 1
## Cuánto se mete hacia dentro del borde la búsqueda de su parte de arriba.
@export_range(0.05, 1.0, 0.05, "suffix:m") var probe_depth: float = 0.3
## Componente vertical mínima de la normal para que la parte de arriba cuente como suelo.
@export_range(0.0, 1.0, 0.05) var min_top_normal_y: float = 0.7
## Holgura entre el cuerpo y el borde.
@export_range(0.0, 0.5, 0.01, "suffix:m") var clearance: float = 0.05


## Borde hacia [param direction] a menos de [param reach] m del centro del cuerpo, con la parte de
## arriba entre [param min_height] y [param max_height] m sobre los pies; null si no hay.
func find_ledge(direction: Vector3, reach: float, min_height: float, max_height: float) -> Ledge:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.is_zero_approx():
		return null
	flat = flat.normalized()
	var space := body.get_world_3d().direct_space_state
	var feet := body.global_position
	# 1. Una pared delante, justo por encima de la altura mínima, de cara al cuerpo.
	var low := feet + Vector3.UP * (min_height + clearance)
	var wall := _ray(space, low, low + flat * reach)
	if wall.is_empty() or (wall["normal"] as Vector3).dot(-flat) < 0.5:
		return null
	var wall_point: Vector3 = wall["position"]
	# 2. Su parte de arriba. Si el borde pasa de la altura máxima, el rayo nace dentro y no da.
	var inside := wall_point + flat * probe_depth
	var top := _ray(
		space,
		Vector3(inside.x, feet.y + max_height + clearance, inside.z),
		Vector3(inside.x, feet.y + min_height, inside.z)
	)
	if top.is_empty() or (top["normal"] as Vector3).y < min_top_normal_y:
		return null
	var top_y: float = (top["position"] as Vector3).y
	# 3. Sitio para el cuerpo encima, ya pasado el filo.
	var past_edge := wall_point + flat * (_radius() + clearance)
	var target := Vector3(past_edge.x, top_y + clearance, past_edge.z)
	if not _fits(space, target):
		return null
	var ledge := Ledge.new()
	ledge.target = target
	ledge.direction = flat
	ledge.height = top_y - feet.y
	return ledge


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask, [body.get_rid()])
	return space.intersect_ray(query)


func _fits(space: PhysicsDirectSpaceState3D, feet: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = body_shape.shape
	query.transform = Transform3D(Basis.IDENTITY, feet + body_shape.position)
	query.collision_mask = collision_mask
	query.exclude = [body.get_rid()]
	return space.intersect_shape(query, 1).is_empty()


func _radius() -> float:
	var capsule := body_shape.shape as CapsuleShape3D
	if capsule == null:
		push_error("LedgeSensor: la forma del cuerpo debe ser una cápsula.")
		return 0.0
	return capsule.radius
