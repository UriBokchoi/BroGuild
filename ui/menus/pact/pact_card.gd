class_name PactCard
extends Button
## La carta de un pacto: su nombre, su frase, el premio (en verde) y la maldición (en rojo), cada
## línea con cómo queda la stat («Daño 100 % → 130 %»). Se pulsa entera y crece hasta que cabe su
## texto.

const WIDTH := 320.0
const HEIGHT := 300.0
## Margen de la columna con el borde de la carta (el de CardParts.column), arriba y abajo.
const COLUMN_MARGIN := 20.0

var pact: PactData

var _column: VBoxContainer


## [param stats]: las del jugador, para enseñar cuánto cambia cada stat (sin ellas, solo lo que hace).
func _init(given: PactData, stats: StatsComponent = null) -> void:
	pact = given
	theme_type_variation = &"CardButton"
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	focus_mode = Control.FOCUS_NONE
	_column = CardParts.column(self)
	CardParts.label(_column, pact.name_key, &"HeaderLabel")
	CardParts.label(_column, pact.flavor_key, &"StatBaseLabel")
	_add_lines(_column, &"PACT_REWARD", pact.rewards, &"BoonLabel", stats)
	_add_lines(_column, &"PACT_CURSE", pact.curses, &"CurseLabel", stats)
	_column.minimum_size_changed.connect(_fit_height)


## Crece hasta que cabe todo su texto (las líneas largas se parten al saber su ancho).
func _fit_height() -> void:
	custom_minimum_size.y = maxf(HEIGHT, _column.get_combined_minimum_size().y + COLUMN_MARGIN * 2.0)


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
