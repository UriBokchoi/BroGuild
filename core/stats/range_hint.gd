class_name RangeHint
extends RefCounted
## Lo que dice el hint de un [code]@export_range[/code]
## ([code]"min,max[,paso][,or_greater][,or_less][,radians_as_degrees][,suffix:…]"[/code]):
## los límites (en las unidades que guarda la propiedad), la unidad y si se muestra en grados.
## Sin rango (un [code]@export[/code] simple), no hay límites ni unidad.

var min_value: float = -INF
var max_value: float = INF
## Unidad que muestra el inspector (p. ej. [code]m/s[/code]); vacía si no tiene.
var suffix: String = ""
## La propiedad guarda radianes pero el inspector muestra grados.
var radians_as_degrees: bool = false


static func parse(hint_string: String) -> RangeHint:
	var hint := RangeHint.new()
	var parts := hint_string.split(",", false)
	if parts.size() < 2:
		return hint
	var flags := PackedStringArray()
	for part: String in parts:
		var flag := part.strip_edges()
		if flag.begins_with("suffix:"):
			hint.suffix = flag.trim_prefix("suffix:")
		else:
			flags.append(flag)
	hint.radians_as_degrees = flags.has("radians_as_degrees")
	# El inspector escribe los límites en grados: la propiedad los necesita en radianes.
	var unit := deg_to_rad(1.0) if hint.radians_as_degrees else 1.0
	if not flags.has("or_less"):
		hint.min_value = parts[0].to_float() * unit
	if not flags.has("or_greater"):
		hint.max_value = parts[1].to_float() * unit
	return hint
