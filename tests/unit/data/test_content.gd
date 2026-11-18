extends GutTest
## Catálogo de contenido (data/content.tres): cada tipo con id, nombre y pista traducidos, y cada
## entrada con id (el de su archivo), nombre, frase e icono. No falta nada de las carpetas de datos
## y las stats que enseña el Archivo existen en sus datos.

const CATALOG := preload("res://data/content.tres")
## De qué carpeta y tipo sale cada pestaña (solo para comprobar que no falta nada).
var _sources: Dictionary[StringName, Array] = {
	&"characters": ["res://data/characters", CharacterData],
	&"weapons": ["res://data/weapons", WeaponData],
	&"runes": ["res://data/runes", RuneData],
	&"items": ["res://data/items", PassiveItemData],
	&"enemies": ["res://data/enemies", EnemyData],
}


func test_every_category_is_complete_and_translated() -> void:
	var ids: Array[StringName] = []
	for category: ContentCategory in CATALOG.categories:
		assert_false(ids.has(category.id), "%s: repetido" % category.id)
		ids.append(category.id)
		assert_ne(tr(category.name_key), String(category.name_key), "%s: nombre sin traducir" % category.id)
		assert_ne(tr(category.hint_key), String(category.hint_key), "%s: pista sin traducir" % category.id)
		assert_false(category.entries.is_empty(), "%s: vacío" % category.id)
	assert_eq(ids.size(), _sources.size())


func test_every_entry_has_what_the_archive_shows() -> void:
	for category: ContentCategory in CATALOG.categories:
		for entry: Resource in category.entries:
			var file := entry.resource_path.get_file().get_basename()
			var id: StringName = entry.get(&"id")
			var name_key: StringName = entry.get(&"name_key")
			var description_key: StringName = entry.get(&"description_key")
			var icon: Texture2D = entry.get(&"icon")
			assert_eq(String(id), file, "%s/%s: id distinto del archivo" % [category.id, file])
			assert_ne(tr(name_key), String(name_key), "%s/%s: nombre sin traducir" % [category.id, file])
			assert_ne(tr(description_key), String(description_key), "%s/%s: frase sin traducir" % [category.id, file])
			assert_not_null(icon, "%s/%s: sin icono" % [category.id, file])


func test_nothing_from_the_data_folders_is_missing() -> void:
	for category: ContentCategory in CATALOG.categories:
		var source: Array = _sources[category.id]
		var path: String = source[0]
		var type: Script = source[1]
		for resource: Resource in ResourceDir.load_all(path, type):
			assert_true(category.has(resource), "%s: falta %s" % [category.id, resource.resource_path])


func test_shown_stats_exist_in_every_entry() -> void:
	for category: ContentCategory in CATALOG.categories:
		for stat: StringName in category.shown_stats:
			for entry: Resource in category.entries:
				assert_true(_has_stat(entry, stat), "%s: «%s» no tiene %s" % [category.id, entry.resource_path, stat])


func test_finds_the_category_of_an_entry() -> void:
	var sword: Resource = load("res://data/weapons/sword.tres")
	assert_eq(CATALOG.category_of(sword).id, &"weapons")
	assert_null(CATALOG.category_of(load("res://data/enemies/target_dummy.tres")), "el muñeco no se descubre")


func _has_stat(entry: Resource, stat: StringName) -> bool:
	var sources: Array[Resource] = []
	if entry is WeaponData:
		sources.append((entry as WeaponData).stats)
	elif entry is EnemyData:
		sources.assign((entry as EnemyData).stat_sources)
	for source: Resource in sources:
		if stat in source:
			return true
	return false
