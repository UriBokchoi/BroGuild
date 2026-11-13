class_name ResourceDir
## Carga todos los Resources de un tipo que hay en una carpeta de datos: añadir contenido (un arma,
## un enemigo…) es dejar su [code].tres[/code] en la carpeta, sin listas que mantener a mano.


## Resources de [param path] (sin subcarpetas) que son [param type] o un subtipo, por nombre de
## archivo. Funciona también en el juego exportado (usa [method ResourceLoader.list_directory]).
static func load_all(path: String, type: Script) -> Array[Resource]:
	var found: Array[Resource] = []
	var files := Array(ResourceLoader.list_directory(path))
	files.sort()
	for file_name: String in files:
		if file_name.ends_with("/"):
			continue
		var resource := load(path.path_join(file_name))
		if resource and is_instance_of(resource, type):
			found.append(resource)
	return found
