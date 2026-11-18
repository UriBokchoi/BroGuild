class_name ContentCategory
extends Resource
## Un tipo de contenido del [ContentCatalog] (personajes, armas, enemigos…): una pestaña del Archivo.
## Sus [member entries] llevan [code]id[/code], [code]name_key[/code], [code]description_key[/code]
## e [code]icon[/code] ([CharacterData], [ItemData], [PassiveItemData], [EnemyData]…).

## Identificador estable (lo que se guarda de lo descubierto).
@export var id: StringName = &""
## Clave de traducción del nombre (el de la pestaña).
@export var name_key: StringName = &""
## Clave de traducción de cómo se descubre lo que aún no se ha descubierto.
@export var hint_key: StringName = &""
## Stats de sus datos que enseña el Archivo de cada entrada, en orden (las de su arma o sus
## [code]stat_sources[/code]); vacío = ninguna.
@export var shown_stats: Array[StringName] = []
## Lo que hay, en el orden en que sale.
@export var entries: Array[Resource] = []


## ¿Está [param entry] entre las suyas?
func has(entry: Resource) -> bool:
	return entry != null and entries.has(entry)
