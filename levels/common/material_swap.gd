class_name MaterialSwap
## Cambia unos materiales por otros en todas las mallas de un árbol de nodos (el material de cada
## superficie y el que tapa toda la malla). Lo usa LevelMap para pintar un tier con los colores de su
## estación reutilizando las mismas piezas.


## Cambia en [param root] y sus hijos cada material que sea una clave de [param swaps] por su valor.
## Devuelve cuántos cambió.
static func apply(root: Node, swaps: Dictionary[Material, Material]) -> int:
	var changed := 0
	for node: Node in root.find_children("*", "GeometryInstance3D", true, false):
		changed += _swap(node as GeometryInstance3D, swaps)
	return changed


static func _swap(instance: GeometryInstance3D, swaps: Dictionary[Material, Material]) -> int:
	var changed := 0
	if instance.material_override and swaps.has(instance.material_override):
		instance.material_override = swaps[instance.material_override]
		changed += 1
	var mesh_instance := instance as MeshInstance3D
	if mesh_instance == null or mesh_instance.mesh == null:
		return changed
	for surface: int in mesh_instance.get_surface_override_material_count():
		var current := mesh_instance.get_active_material(surface)
		if current and swaps.has(current):
			mesh_instance.set_surface_override_material(surface, swaps[current])
			changed += 1
	return changed
