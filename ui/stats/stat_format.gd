class_name StatFormat
extends RefCounted
## Da formato a un valor de stat para mostrarlo, a partir de su propiedad en los datos: la unidad
## de su [code]@export_range[/code], grados si guarda radianes y sin decimales si es entera.

## Decimales como máximo; los ceros del final se quitan.
const MAX_DECIMALS := 2


## [param value] con su unidad, p. ej. [code]"9 m/s"[/code] o [code]"720 °/s"[/code].
static func format(value: float, property: Dictionary) -> String:
	var hint_type: int = property["hint"]
	var hint_string: String = property["hint_string"]
	var type: int = property["type"]
	var hint := RangeHint.parse(hint_string) if hint_type == PROPERTY_HINT_RANGE else RangeHint.new()
	var shown := rad_to_deg(value) if hint.radians_as_degrees else value
	var text := str(roundi(shown)) if type == TYPE_INT else _trim_zeros(String.num(shown, MAX_DECIMALS))
	return text if hint.suffix.is_empty() else "%s %s" % [text, hint.suffix]


## Clave de traducción del nombre de una stat: [code]run_speed[/code] → [code]STAT_RUN_SPEED[/code].
static func name_key(stat: StringName) -> String:
	return "STAT_%s" % String(stat).to_upper()


## Clave de traducción de un grupo de stats ([code]@export_group[/code]):
## [code]run[/code] → [code]STAT_GROUP_RUN[/code].
static func group_key(group: String) -> String:
	return "STAT_GROUP_%s" % group.to_upper()


## [code]"9.0"[/code] → [code]"9"[/code], [code]"0.50"[/code] → [code]"0.5"[/code]
## (String.num deja un «.0» en 4.7.2).
static func _trim_zeros(text: String) -> String:
	if not text.contains("."):
		return text
	return text.rstrip("0").rstrip(".")
