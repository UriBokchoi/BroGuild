class_name CardParts
## Piezas de las cartas de elegir (subir de nivel, objetos): sus líneas de texto y el borde del color
## de una rareza.

## Grosor del borde de color de la rareza.
const RARITY_BORDER := 4
## Estados del botón que llevan el borde de la rareza (también desactivado: la carta que gira en la
## ruleta).
const RARITY_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]


## Una línea de [param text_value] con el estilo [param variation], que no recibe el ratón (la carta
## se pulsa entera).
static func label(lines: VBoxContainer, text_value: String, variation: StringName) -> Label:
	var line := Label.new()
	line.text = text_value
	line.theme_type_variation = variation
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(line)
	return line


## Pinta el borde de [param card] del color de [param rarity] (sobre el estilo de la carta del tema).
## Llamar ya en el árbol (con el tema puesto).
static func rarity_border(card: Button, rarity: Rarity) -> void:
	for state: StringName in RARITY_STATES:
		var box := card.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if box == null:
			continue
		box.border_color = rarity.color
		box.set_border_width_all(RARITY_BORDER)
		card.add_theme_stylebox_override(state, box)


## La columna de la carta [param card], que la llena con su margen (la carta se pulsa entera).
static func column(card: Button) -> VBoxContainer:
	var lines := VBoxContainer.new()
	lines.theme_type_variation = &"CardColumn"
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	card.add_child(lines)
	return lines


## El icono [param texture] centrado, de [param height] de alto.
static func icon(lines: VBoxContainer, texture: Texture2D, height: float) -> void:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.custom_minimum_size = Vector2(0.0, height)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(picture)
