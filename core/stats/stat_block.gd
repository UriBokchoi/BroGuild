class_name StatBlock
extends RefCounted
## Stats de una entidad: valor base + [StatModifier] → valor final. Es el único sitio donde
## se calcula una stat (CLAUDE.md, regla 7).
##
## Valor final: [code](base + Σ FLAT) × (1 + Σ PERCENT) × Π MULTIPLIER[/code], limitado a
## [mínimo, máximo] y redondeado al entero más cercano si la stat es entera. Se recalcula al
## cambiar sus modificadores y se guarda, así que leerlo cada frame no cuesta nada.

## Cambió el valor final de una stat. No se emite si un cambio la deja igual.
signal stat_changed(stat: StringName, value: float, previous: float)

## Marcas de una variable con [code]@export[/code] (sin [code]@export[/code] no es stat).
const _EXPORTED_VARIABLE: int = (
	PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
)

var _stats: Dictionary[StringName, StatState] = {}


## Define una stat con su base y sus límites. Cada stat se define una sola vez.
## Devuelve [code]false[/code] (y avisa del error) si no se ha podido definir.
func define(
	stat: StringName,
	base: float,
	min_value: float = -INF,
	max_value: float = INF,
	is_integer: bool = false,
) -> bool:
	if stat.is_empty():
		push_error("StatBlock: una stat necesita nombre.")
		return false
	if _stats.has(stat):
		push_error("StatBlock: la stat '%s' ya está definida." % stat)
		return false
	if min_value > max_value:
		push_error("StatBlock: la stat '%s' tiene el mínimo por encima del máximo." % stat)
		return false
	var state := StatState.new()
	state.base = base
	state.min_value = min_value
	state.max_value = max_value
	state.is_integer = is_integer
	state.value = _calculate(state)
	_stats[stat] = state
	return true


## Define una stat por cada número exportado de [param data] y devuelve sus nombres.
## Son stats los [code]float[/code] e [code]int[/code] con [code]@export[/code] o
## [code]@export_range[/code]; enums, bools, curvas y demás no lo son. El rango del inspector
## es también el límite en juego: el mínimo y el máximo de [code]@export_range[/code], salvo
## con [code]or_less[/code] u [code]or_greater[/code]. Los [code]int[/code] son stats enteras.
func define_from_resource(data: Resource) -> Array[StringName]:
	var defined: Array[StringName] = []
	for property: Dictionary in data.get_property_list():
		if not _is_stat_property(property):
			continue
		var stat: StringName = property["name"]
		var hint_string: String = property["hint_string"]
		var type: int = property["type"]
		var base: float = data.get(stat)
		var hint := RangeHint.parse(hint_string)
		if define(stat, base, hint.min_value, hint.max_value, type == TYPE_INT):
			defined.append(stat)
	return defined


func has_stat(stat: StringName) -> bool:
	return _stats.has(stat)


## Nombres de todas las stats, en el orden en que se definieron.
func get_stats() -> Array[StringName]:
	var stats: Array[StringName] = []
	stats.assign(_stats.keys())
	return stats


## Valor base de [param stat], sin modificadores. Una stat que no existe es un error y vale 0.
func get_base(stat: StringName) -> float:
	var state := _get_state(stat)
	return state.base if state else 0.0


## Valor final de [param stat]. Una stat que no existe es un error y vale 0.
func get_value(stat: StringName) -> float:
	var state := _get_state(stat)
	return state.value if state else 0.0


## Valor final de [param stat] redondeado a entero (para stats enteras: saltos, cargas…).
func get_int(stat: StringName) -> int:
	return roundi(get_value(stat))


## Aplica [param modifier] en nombre de [param source] (la mejora, el pacto, el rasgo…),
## que sirve para quitarlo después con [method remove_modifiers_from]. Aplicar el mismo
## modificador varias veces lo acumula.
func add_modifier(modifier: StatModifier, source: Object) -> void:
	if modifier == null or source == null:
		push_error("StatBlock: add_modifier necesita un modificador y su origen.")
		return
	var state := _get_state(modifier.stat)
	if state == null:
		return
	var applied := AppliedModifier.new()
	applied.modifier = modifier
	applied.source = source
	state.applied.append(applied)
	_refresh(modifier.stat, state)


## Quita todos los modificadores que aplicó [param source].
func remove_modifiers_from(source: Object) -> void:
	var changed: Array[StringName] = []
	for stat: StringName in _stats:
		var state: StatState = _stats[stat]
		var before := state.applied.size()
		for i: int in range(state.applied.size() - 1, -1, -1):
			if state.applied[i].source == source:
				state.applied.remove_at(i)
		if state.applied.size() != before:
			changed.append(stat)
	# Se avisa al final: así quien escuche puede tocar el bloque sin romper el recorrido.
	for stat: StringName in changed:
		_refresh(stat, _stats[stat])


func _get_state(stat: StringName) -> StatState:
	var state: StatState = _stats.get(stat)
	if state == null:
		push_error("StatBlock: la stat '%s' no existe." % stat)
	return state


func _refresh(stat: StringName, state: StatState) -> void:
	var previous := state.value
	state.value = _calculate(state)
	if state.value != previous:
		stat_changed.emit(stat, state.value, previous)


static func _calculate(state: StatState) -> float:
	var flat := 0.0
	var percent := 0.0
	var multiplier := 1.0
	for applied: AppliedModifier in state.applied:
		match applied.modifier.kind:
			StatModifier.Kind.FLAT:
				flat += applied.modifier.value
			StatModifier.Kind.PERCENT:
				percent += applied.modifier.value
			StatModifier.Kind.MULTIPLIER:
				multiplier *= applied.modifier.value
			_:
				push_error("StatBlock: tipo de modificador sin cálculo: %d." % applied.modifier.kind)
	var value := clampf(
		(state.base + flat) * (1.0 + percent) * multiplier, state.min_value, state.max_value
	)
	return roundf(value) if state.is_integer else value


static func _is_stat_property(property: Dictionary) -> bool:
	var usage: int = property["usage"]
	var type: int = property["type"]
	var hint: int = property["hint"]
	return (
		(usage & _EXPORTED_VARIABLE) == _EXPORTED_VARIABLE
		and (type == TYPE_FLOAT or type == TYPE_INT)
		and (hint == PROPERTY_HINT_NONE or hint == PROPERTY_HINT_RANGE)
	)


## Estado interno de una stat.
class StatState:
	var base: float = 0.0
	var min_value: float = -INF
	var max_value: float = INF
	var is_integer: bool = false
	var value: float = 0.0
	var applied: Array[AppliedModifier] = []


## Modificador aplicado y quién lo aplicó.
class AppliedModifier:
	var modifier: StatModifier
	var source: Object
