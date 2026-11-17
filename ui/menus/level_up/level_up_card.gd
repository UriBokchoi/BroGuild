class_name LevelUpCard
extends Button
## Carta de una opción al subir de nivel: su icono, qué es (arma o runa), su nombre, «Nuevo» o el
## nivel al que sube, su descripción y lo que mejora. Las mejoras llevan su rareza: el borde de la
## carta y su nombre van del color de la rareza ([member Rarity.color]). Se pulsa entera.

## Grosor del borde de color de la rareza.
const RARITY_BORDER := 4
## Estados del botón que llevan el borde de la rareza.
const RARITY_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"hover_pressed"]
## Alto del icono.
const ICON_HEIGHT := 72.0
## Alto de cada línea de más (rareza, mejoras de varias stats).
const LINE_HEIGHT := 28.0

var option: LevelUpOption


func _init(offered: LevelUpOption) -> void:
	option = offered
	theme_type_variation = &"CardButton"
	var extra_lines := maxi(option.modifiers().size() - 1, 0) + (1 if option.rarity() else 0)
	var height := 340.0 + (ICON_HEIGHT if option.item.icon else 0.0) + LINE_HEIGHT * extra_lines
	custom_minimum_size = Vector2(260.0, height)
	focus_mode = Control.FOCUS_NONE
	var column := VBoxContainer.new()
	column.theme_type_variation = &"CardColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	add_child(column)
	if option.item.icon:
		var picture := TextureRect.new()
		picture.texture = option.item.icon
		picture.custom_minimum_size = Vector2(0.0, ICON_HEIGHT)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(picture)
	var rarity := option.rarity()
	if rarity:
		var rarity_label := _label(column, rarity.name_key, &"StatGroupLabel")
		rarity_label.add_theme_color_override(&"font_color", rarity.color)
	_label(column, option.item.kind_key(), &"StatGroupLabel")
	_label(column, option.item.name_key, &"HeaderLabel")
	var level_text := tr(&"LEVEL_UP_NEW") if option.is_new() else tr(&"LEVEL_UP_LEVEL") % [option.level - 1, option.level]
	_label(column, level_text, &"StatValueLabel")
	_label(column, option.item.description_key, &"StatBaseLabel")
	for modifier: StatModifier in option.modifiers():
		_label(column, ModifierFormat.describe(modifier), &"StatModifiedLabel")


func _ready() -> void:
	var rarity := option.rarity()
	if rarity == null:
		return
	# El borde, del color de la rareza (sobre el estilo de la carta del tema).
	for state: StringName in RARITY_STATES:
		var box := get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if box == null:
			continue
		box.border_color = rarity.color
		box.set_border_width_all(RARITY_BORDER)
		add_theme_stylebox_override(state, box)


func _label(column: VBoxContainer, text_value: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text_value
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
	return label
