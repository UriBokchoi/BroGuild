class_name BreakableScatter
extends Node3D
## Reparte rompibles (calaveras, bolsitas…) o las llaves del jefe por el nivel al empezar la
## partida, en sitios distintos cada vez (con la semilla de la partida). Cada uno cae sobre el suelo
## o encima de una meseta, nunca dentro de un árbol o un prop, y separado de los demás. Los que no
## encuentran sitio tras varios intentos no salen.

## Qué repartir y cuántos.
@export var entries: Array[ScatterEntry] = []
## Mitad del rectángulo (x, z) donde se reparten, centrado en este nodo.
@export var half_extent: Vector2 = Vector2.ZERO
## Hueco libre que necesita cada uno (radio).
@export_range(0.1, 5.0, 0.05, "suffix:m") var clearance: float = 0.8
## Distancia mínima entre dos rompibles.
@export_range(0.0, 20.0, 0.5, "suffix:m") var min_spacing: float = 3.0
## Distancia mínima al centro de este nodo (las llaves del jefe, lejos del punto de aparición).
@export_range(0.0, 200.0, 0.5, "suffix:m") var min_center_distance: float = 0.0
## Capas que cuentan como suelo y como obstáculo.
@export_flags_3d_physics var world_mask: int = 1
## Altura desde la que se busca el suelo.
@export_range(1.0, 200.0, 1.0, "suffix:m") var probe_height: float = 40.0
## Intentos por rompible.
@export_range(1, 64, 1) var attempts: int = 12
## Diferencia de altura máxima del suelo bajo el hueco (descarta la tapa de un tronco o de un prop).
@export_range(0.0, 2.0, 0.05, "suffix:m") var max_step: float = 0.3
## Si reparte solo al empezar (los tests llaman a [method scatter]).
@export var scatter_on_ready: bool = true
## Inclinación máxima del suelo (normal hacia arriba, de 0 a 1).
@export_range(0.0, 1.0, 0.05) var min_up: float = 0.8

## Azar del reparto. Si no se asigna antes de entrar en el árbol, el flujo de botín de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _placed: Array[Vector3] = []


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.LOOT)
	if not scatter_on_ready:
		return
	# La física del nivel tiene que estar lista para buscar el suelo.
	await get_tree().physics_frame
	scatter()


## Reparte todo lo de [member entries]. Devuelve cuántos ha colocado.
func scatter() -> int:
	var placed := 0
	for entry: ScatterEntry in entries:
		for _index: int in entry.count:
			var spot: Variant = _find_spot()
			if spot == null:
				continue
			var item := entry.scene.instantiate() as Node3D
			add_child(item)
			item.global_position = spot
			item.rotation.y = rng.randf_range(0.0, TAU)
			placed += 1
	return placed


func _find_spot() -> Variant:
	var space := get_world_3d().direct_space_state
	for _attempt: int in attempts:
		var local := Vector2(rng.randf_range(-half_extent.x, half_extent.x), rng.randf_range(-half_extent.y, half_extent.y))
		if local.length() < min_center_distance:
			continue
		var top := global_position + Vector3(local.x, probe_height, local.y)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * probe_height * 2.0, world_mask))
		if hit.is_empty():
			continue
		var normal: Vector3 = hit["normal"]
		var ground: Vector3 = hit["position"]
		if normal.y < min_up or _too_close(ground) or not _flat_around(space, ground) or _blocked(space, ground):
			continue
		_placed.append(ground)
		return ground
	return null


func _too_close(spot: Vector3) -> bool:
	for other: Vector3 in _placed:
		if spot.distance_to(other) < min_spacing:
			return true
	return false


## ¿Choca con algo una esfera de [member clearance] apoyada en [param ground]?
func _blocked(space: PhysicsDirectSpaceState3D, ground: Vector3) -> bool:
	var sphere := SphereShape3D.new()
	sphere.radius = clearance
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.collision_mask = world_mask
	# Un poco por encima del suelo, para no contarlo como obstáculo.
	query.transform = Transform3D(Basis.IDENTITY, ground + Vector3.UP * (clearance + 0.05))
	return not space.intersect_shape(query, 1).is_empty()


## ¿Hay suelo a la misma altura alrededor de [param ground], a [member clearance]?
func _flat_around(space: PhysicsDirectSpaceState3D, ground: Vector3) -> bool:
	for side: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var top := ground + side * clearance + Vector3.UP * probe_height
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * probe_height * 2.0, world_mask))
		if hit.is_empty():
			return false
		var height: Vector3 = hit["position"]
		if absf(height.y - ground.y) > max_step:
			return false
	return true
