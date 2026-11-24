class_name UpgradableStats
extends RefCounted
## Las stats que algo del juego puede cambiar: las de algún modificador ([StatModifier]) o mejora de
## arma o runa ([UpgradeStat]) en los datos (objetos, runas, armas, personajes, power-ups…). La vista
## de stats solo enseña esas: las demás (los márgenes del salto, tiempos internos del movimiento…) no
## cambian nunca y tapan las importantes. Una mejora nueva sobre una stat la hace aparecer sola.
##
## Se buscan en los recursos de [constant DIRS] (con sus subcarpetas) la primera vez que se pregunta;
## [method warm_up] lo hace al cargar el nivel, para que abrir la vista no dé un tirón.

## Carpetas de datos donde hay cosas que cambian al jugador. No se mira todo [code]res://data[/code]:
## cargar un nivel o un mapa carga también sus escenas (más de un segundo). Si algo nuevo cambia al
## jugador desde otra carpeta (los pactos), se añade aquí; un test avisa si falta alguna.
const DIRS: Array[String] = [
	"res://data/items",
	"res://data/runes",
	"res://data/weapons",
	"res://data/characters",
	"res://data/pickups",
	"res://data/slots",
	"res://data/progression",
	"res://data/player",
]
## Stats que cambian aunque no lo diga ningún dato (las cambia el código: la dificultad sube sola
## con el reloj de la ronda).
const ALWAYS: Array[StringName] = [&"difficulty"]

static var _stats: Dictionary[StringName, bool] = {}
static var _collected: bool = false


## ¿Puede cambiar [param stat] algo del juego?
static func has(stat: StringName) -> bool:
	if not _collected:
		_collect()
	return _stats.has(stat)


## Busca las stats de antemano (al cargar el menú y el nivel).
static func warm_up() -> void:
	if not _collected:
		_collect()


## Las stats que cambian los datos de [param dirs] (con sus subcarpetas), sin [constant ALWAYS].
static func found_in(dirs: Array[String]) -> Dictionary[StringName, bool]:
	var found: Dictionary[StringName, bool] = {}
	var seen: Dictionary = {}
	for dir: String in dirs:
		for path: String in _resource_paths(dir):
			_visit(load(path), seen, found)
	return found


static func _collect() -> void:
	_collected = true
	_stats = found_in(DIRS)
	for stat: StringName in ALWAYS:
		_stats[stat] = true


## Los recursos de [param dir] y sus subcarpetas (también en el juego exportado: ver
## [method ResourceLoader.list_directory]).
static func _resource_paths(dir: String) -> PackedStringArray:
	var paths := PackedStringArray()
	for entry: String in ResourceLoader.list_directory(dir):
		var path := dir.path_join(entry)
		if entry.ends_with("/"):
			paths.append_array(_resource_paths(path.trim_suffix("/")))
		elif entry.get_extension() in ["tres", "res"]:
			paths.append(path)
	return paths


## Apunta las stats de [param value] y, si es un recurso de datos (con script propio), las de todo lo
## que lleva dentro. Los recursos del motor (texturas, mallas, escenas…) no se miran.
static func _visit(value: Variant, seen: Dictionary, found: Dictionary[StringName, bool]) -> void:
	if value is StatModifier:
		found[(value as StatModifier).stat] = true
	elif value is UpgradeStat:
		found[(value as UpgradeStat).stat] = true
	elif value is Array:
		for item: Variant in value:
			_visit(item, seen, found)
	elif value is Dictionary:
		for item: Variant in (value as Dictionary).values():
			_visit(item, seen, found)
	elif value is Resource and (value as Resource).get_script() != null and not seen.has(value):
		seen[value] = true
		var resource := value as Resource
		for property: Dictionary in resource.get_property_list():
			var usage: int = property["usage"]
			if usage & PROPERTY_USAGE_STORAGE and usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				_visit(resource.get(property["name"] as String), seen, found)
