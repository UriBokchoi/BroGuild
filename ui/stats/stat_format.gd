class_name StatFormat
extends RefCounted
## Da formato a un valor de stat para mostrarlo, a partir de su propiedad en los datos: la unidad
## de su [code]@export_range[/code], grados si guarda radianes y sin decimales si es entera.

## Decimales como máximo; los ceros del final se quitan.
const MAX_DECIMALS := 2

## Unidad de cada stat que la tiene clara (ver [method range_hint]). Se llena la primera vez.
static var _hints: Dictionary[StringName, RangeHint] = {}
static var _hints_collected: bool = false


## [param value] con su unidad, p. ej. [code]"9 m/s"[/code] o [code]"720 °/s"[/code].
static func format(value: float, property: Dictionary) -> String:
	var hint_type: int = property["hint"]
	var hint_string: String = property["hint_string"]
	var type: int = property["type"]
	var hint := RangeHint.parse(hint_string) if hint_type == PROPERTY_HINT_RANGE else RangeHint.new()
	var shown := rad_to_deg(value) if hint.radians_as_degrees else value
	var text := str(roundi(shown)) if type == TYPE_INT else _trim_zeros(String.num(shown, MAX_DECIMALS))
	return text if hint.suffix.is_empty() else "%s %s" % [text, hint.suffix]


## Cómo se muestra [param stat] (su unidad y si guarda radianes), según el [code]@export_range[/code]
## de las clases de datos ([Resource]) que la declaran. Sin unidad si ninguna la declara o si dos la
## declaran con unidades distintas (p. ej. [code]damage[/code]: número en un arma, % en el jugador),
## porque entonces depende de a quién se aplique.
static func range_hint(stat: StringName) -> RangeHint:
	if not _hints_collected:
		_collect_hints()
	return _hints[stat] if _hints.has(stat) else RangeHint.new()


## Clave de traducción del nombre de una stat: [code]run_speed[/code] → [code]STAT_RUN_SPEED[/code].
static func name_key(stat: StringName) -> String:
	return "STAT_%s" % String(stat).to_upper()


## Clave de traducción de un grupo de stats ([code]@export_group[/code]):
## [code]run[/code] → [code]STAT_GROUP_RUN[/code].
static func group_key(group: String) -> String:
	return "STAT_GROUP_%s" % group.to_upper()


## [param value] con [constant MAX_DECIMALS] decimales como mucho y sin ceros al final.
static func number(value: float) -> String:
	return _trim_zeros(String.num(value, MAX_DECIMALS))


## [code]"9.0"[/code] → [code]"9"[/code], [code]"0.50"[/code] → [code]"0.5"[/code]
## (String.num deja un «.0» en 4.7.2).
static func _trim_zeros(text: String) -> String:
	if not text.contains("."):
		return text
	return text.rstrip("0").rstrip(".")


## Recorre las clases de datos del proyecto (sin addons ni tests) y apunta la unidad de cada stat;
## las que salen con unidades distintas se quedan sin ella.
static func _collect_hints() -> void:
	_hints_collected = true
	var units: Dictionary[StringName, String] = {}
	var ambiguous: Dictionary[StringName, bool] = {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		var path: String = entry["path"]
		if path.begins_with("res://addons/") or path.begins_with("res://tests/"):
			continue
		var script := load(path) as Script
		if script == null or not ClassDB.is_parent_class(script.get_instance_base_type(), &"Resource"):
			continue
		for property: Dictionary in script.get_script_property_list():
			if not StatBlock.is_stat_property(property):
				continue
			var hint_type: int = property["hint"]
			var hint_string: String = property["hint_string"]
			var stat := StringName(property["name"] as String)
			var hint := RangeHint.parse(hint_string) if hint_type == PROPERTY_HINT_RANGE else RangeHint.new()
			var unit := "%s|%s" % [hint.suffix, hint.radians_as_degrees]
			if units.has(stat) and units[stat] != unit:
				ambiguous[stat] = true
			units[stat] = unit
			_hints[stat] = hint
	for stat: StringName in ambiguous:
		_hints.erase(stat)
