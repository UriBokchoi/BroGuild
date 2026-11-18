class_name ContentCatalog
extends Resource
## Todo el contenido del juego que se puede descubrir, por tipos ([ContentCategory]): de aquí salen
## las pestañas del Archivo y lo que apunta el [ArchiveRecorder]. Vive en
## [code]data/content.tres[/code]; un test comprueba que no falta nada de las carpetas de datos.

@export var categories: Array[ContentCategory] = []


## El tipo de [param entry] (el primero que la tiene), o [code]null[/code] si no está.
func category_of(entry: Resource) -> ContentCategory:
	for category: ContentCategory in categories:
		if category.has(entry):
			return category
	return null
