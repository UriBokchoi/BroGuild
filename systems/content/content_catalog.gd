class_name ContentCatalog
extends Resource
## Todo el contenido del juego que se puede descubrir, por tipos ([ContentCategory]): de aquí salen
## las pestañas del Archivo y lo que apunta el [ArchiveRecorder]. Vive en
## [code]data/content.tres[/code]; un test comprueba que no falta nada de las carpetas de datos.

@export var categories: Array[ContentCategory] = []


## La entrada con id [param entry_id] del tipo [param category_id], o null si no está.
func find(category_id: StringName, entry_id: StringName) -> Resource:
	for category: ContentCategory in categories:
		if category.id != category_id:
			continue
		for entry: Resource in category.entries:
			if entry.get(&"id") == entry_id:
				return entry
	return null


## El tipo de [param entry] (el primero que la tiene), o [code]null[/code] si no está.
func category_of(entry: Resource) -> ContentCategory:
	for category: ContentCategory in categories:
		if category.has(entry):
			return category
	return null
