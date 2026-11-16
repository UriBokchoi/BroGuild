class_name TargetFinder
extends RefCounted
## Busca objetivos para un arma: las hurtbox de la capa indicada más cercanas a un punto, dentro de
## un radio. Hace una sola consulta de física por búsqueda; con muchos enemigos dentro del radio,
## solo mira los primeros [member max_candidates] que devuelve la física.

## Capas de física de los objetivos (p. ej. [code]enemy_hurtbox[/code]).
var mask: int = 0
## Cuántos resultados pide a la física como mucho.
var max_candidates: int = 64

var _sphere := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()


func _init(target_mask: int) -> void:
	mask = target_mask
	_query.shape = _sphere
	_query.collide_with_areas = true
	_query.collide_with_bodies = false


## Hasta [param count] objetivos dentro de [param radius] alrededor de [param origin], del más
## cercano al más lejano (en 3D: un enemigo en lo alto de una pila está más lejos).
func nearest(space: PhysicsDirectSpaceState3D, origin: Vector3, radius: float, count: int) -> Array[Node3D]:
	_sphere.radius = radius
	_query.transform = Transform3D(Basis.IDENTITY, origin)
	_query.collision_mask = mask
	var found: Array[Node3D] = []
	for hit: Dictionary in space.intersect_shape(_query, max_candidates):
		var target := hit["collider"] as Node3D
		if target and not found.has(target):
			found.append(target)
	found.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return origin.distance_squared_to(aim_point(a)) < origin.distance_squared_to(aim_point(b)))
	return found.slice(0, count)


## Punto al que apuntar en [param target]: el centro de su hurtbox (no sus pies), o su posición si
## no es una hurtbox.
static func aim_point(target: Node3D) -> Vector3:
	var hurtbox := target as HurtboxComponent
	return hurtbox.get_center() if hurtbox else target.global_position
