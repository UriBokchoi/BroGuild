class_name TargetFinder
extends RefCounted
## Busca objetivos para un arma: los más cercanos a un punto dentro de un radio y, si se le pide,
## solo los que se ven desde ahí (sin un árbol o una meseta en medio). Hace una sola consulta de
## física por búsqueda y los rayos de vista solo hasta tener los que hacen falta.

## Capas de física de los objetivos (p. ej. [code]enemy_hurtbox[/code]).
var mask: int = 0
## Capas que tapan la vista (el mundo). 0 = no se mira si se ven.
var sight_mask: int = 0
## Cuántos resultados pide a la física como mucho.
var max_candidates: int = 64

var _sphere := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()
var _ray := PhysicsRayQueryParameters3D.new()


func _init(target_mask: int, blocking_mask: int = 0) -> void:
	mask = target_mask
	sight_mask = blocking_mask
	_query.shape = _sphere
	_query.collide_with_areas = true
	_query.collide_with_bodies = false


## Hasta [param count] objetivos dentro de [param radius] alrededor de [param origin] que se ven
## desde ahí, del más cercano al más lejano (en 3D: un enemigo en lo alto de una pila está más lejos).
func nearest(space: PhysicsDirectSpaceState3D, origin: Vector3, radius: float, count: int) -> Array[Node3D]:
	return nearest_to(space, origin, radius, count, origin)


## Como [method nearest], pero ordenados por lo cerca que están de [param focus] (la mira al
## apuntar): siguen teniendo que estar a [param radius] de [param origin] y verse desde ahí.
func nearest_to(
	space: PhysicsDirectSpaceState3D,
	origin: Vector3,
	radius: float,
	count: int,
	focus: Vector3,
) -> Array[Node3D]:
	_sphere.radius = radius
	_query.transform = Transform3D(Basis.IDENTITY, origin)
	_query.collision_mask = mask
	var found: Array[Node3D] = []
	for hit: Dictionary in space.intersect_shape(_query, max_candidates):
		var target := hit["collider"] as Node3D
		if target and not found.has(target):
			found.append(target)
	found.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return focus.distance_squared_to(aim_point(a)) < focus.distance_squared_to(aim_point(b)))
	if sight_mask == 0:
		return found.slice(0, count)
	var seen: Array[Node3D] = []
	for target: Node3D in found:
		if can_see(space, origin, aim_point(target)):
			seen.append(target)
			if seen.size() >= count:
				break
	return seen


## ¿Se ve [param to] desde [param from]? (Nada de [member sight_mask] en medio.)
func can_see(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	if sight_mask == 0:
		return true
	_ray.from = from
	_ray.to = to
	_ray.collision_mask = sight_mask
	return space.intersect_ray(_ray).is_empty()


## Punto al que apuntar en [param target]: el centro de su hurtbox (no sus pies), o su posición si
## no es una hurtbox.
static func aim_point(target: Node3D) -> Vector3:
	var hurtbox := target as HurtboxComponent
	return hurtbox.get_center() if hurtbox else target.global_position
