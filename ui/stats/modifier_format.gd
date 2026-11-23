class_name ModifierFormat
extends RefCounted
## Describe un [StatModifier] para mostrarlo con el nombre traducido de su stat: «+10 % Daño»,
## «+20 Vida máxima», «×0.8 Tiempo entre ataques». Lo que suma lleva la unidad de la stat si la
## tiene clara ([method StatFormat.range_hint]): «+10 % Probabilidad de crítico», «+0.5 m/s …».
## Con las stats a las que se aplicaría, también cuánto cambia: «Daño 18 → 22» ([method describe_changes])
## o solo «18 → 22» ([method changes]).


static func describe(modifier: StatModifier) -> String:
	var stat_name := TranslationServer.translate(StatFormat.name_key(modifier.stat))
	match modifier.kind:
		StatModifier.Kind.FLAT:
			return "%s %s" % [_flat(modifier), stat_name]
		StatModifier.Kind.PERCENT:
			return "%s %% %s" % [_signed(modifier.value * 100.0), stat_name]
		_:
			return "×%s %s" % [StatFormat.number(modifier.value), stat_name]


## Una línea por modificador de [param modifiers], en su orden.
static func describe_all(modifiers: Array[StatModifier]) -> PackedStringArray:
	var lines := PackedStringArray()
	for modifier: StatModifier in modifiers:
		lines.append(describe(modifier))
	return lines


## Una línea por stat de [param modifiers] para las cartas de mejora: con [param stats], su nombre, el
## valor de ahora y el que quedará con todos ellos («Daño 18 → 22»; si varios tocan la misma stat, una
## sola línea). Sin [param stats], o si no tienen esa stat, lo que hace el modificador («+4 Daño»).
static func describe_changes(modifiers: Array[StatModifier], stats: StatsComponent) -> PackedStringArray:
	var lines := PackedStringArray()
	var told: Dictionary[StringName, bool] = {}
	for modifier: StatModifier in modifiers:
		var values := change(modifier.stat, stats, modifiers)
		if values.is_empty():
			lines.append(describe(modifier))
		elif not told.has(modifier.stat):
			told[modifier.stat] = true
			lines.append("%s %s" % [TranslationServer.translate(StatFormat.name_key(modifier.stat)), values])
	return lines


## Cómo quedaría cada stat de [param modifiers] en [param stats]: el valor de ahora y el que tendrá con
## todos ellos, en sus unidades («18 → 22»). Una línea por modificador, en su orden; vacía si no hay
## [param stats], si no tienen esa stat o si ya la dijo un modificador anterior de la misma stat.
static func changes(modifiers: Array[StatModifier], stats: StatsComponent) -> PackedStringArray:
	var lines := PackedStringArray()
	var told: Dictionary[StringName, bool] = {}
	for modifier: StatModifier in modifiers:
		var line := ""
		if not told.has(modifier.stat):
			told[modifier.stat] = true
			line = change(modifier.stat, stats, modifiers)
		lines.append(line)
	return lines


## El valor de [param stat] en [param stats] y el que tendría con [param modifiers]: «18 → 22». Vacío
## si no se sabe (sin stats o sin esa stat).
static func change(stat: StringName, stats: StatsComponent, modifiers: Array[StatModifier]) -> String:
	if stats == null or not stats.has_stat(stat):
		return ""
	var property := stats.get_property(stat)
	if property.is_empty():
		return ""
	var before := StatFormat.format(stats.get_value(stat), property)
	var after := StatFormat.format(stats.preview(stat, modifiers), property)
	return "%s → %s" % [before, after]


## Lo que suma [param modifier], con la unidad de su stat (y en grados si la stat guarda radianes).
static func _flat(modifier: StatModifier) -> String:
	var hint := StatFormat.range_hint(modifier.stat)
	var text := _signed(rad_to_deg(modifier.value) if hint.radians_as_degrees else modifier.value)
	return text if hint.suffix.is_empty() else "%s %s" % [text, hint.suffix]


static func _signed(value: float) -> String:
	return ("+" if value >= 0.0 else "−") + StatFormat.number(absf(value))
