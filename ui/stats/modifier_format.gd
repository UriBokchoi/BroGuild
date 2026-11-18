class_name ModifierFormat
extends RefCounted
## Describe un [StatModifier] para mostrarlo con el nombre traducido de su stat: «+10 % Daño»,
## «+20 Vida máxima», «×0.8 Tiempo entre ataques».


static func describe(modifier: StatModifier) -> String:
	var stat_name := TranslationServer.translate(StatFormat.name_key(modifier.stat))
	match modifier.kind:
		StatModifier.Kind.FLAT:
			return "%s %s" % [_signed(modifier.value), stat_name]
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


static func _signed(value: float) -> String:
	return ("+" if value >= 0.0 else "−") + StatFormat.number(absf(value))
