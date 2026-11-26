class_name PactCard
extends Button
## La carta de un pacto: su nombre, su frase, el premio (en verde) y la maldición (en rojo), cada
## línea con cómo queda la stat («Daño 100 % → 130 %»). Se pulsa entera y crece hasta que cabe su
## texto.

const WIDTH := 320.0
const HEIGHT := 300.0

var pact: PactData


## [param stats]: las del jugador, para enseñar cuánto cambia cada stat (sin ellas, solo lo que hace).
func _init(given: PactData, stats: StatsComponent = null) -> void:
	pact = given
	theme_type_variation = &"CardButton"
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	focus_mode = Control.FOCUS_NONE
	var column := CardParts.column(self)
	CardParts.label(column, pact.name_key, &"HeaderLabel")
	CardParts.label(column, pact.flavor_key, &"StatBaseLabel")
	_add_lines(column, &"PACT_REWARD", pact.rewards, &"BoonLabel", stats)
	_add_lines(column, &"PACT_CURSE", pact.curses, &"CurseLabel", stats)
	CardParts.fit_height(self, column)


## El título [param title_key] y una línea por modificador de [param modifiers], con su cambio.
func _add_lines(
	column: VBoxContainer,
	title_key: StringName,
	modifiers: Array[StatModifier],
	variation: StringName,
	stats: StatsComponent,
) -> void:
	CardParts.label(column, title_key, &"StatGroupLabel")
	var changes := ModifierFormat.changes(modifiers, stats)
	for index: int in modifiers.size():
		CardParts.label(column, ModifierFormat.describe(modifiers[index]), variation)
		if not changes[index].is_empty():
			CardParts.label(column, changes[index], &"StatBaseLabel")
