class_name LevelUpCard
extends Button
## Carta de una opción al subir de nivel: su icono, qué es (arma o runa), su nombre, «Nuevo» o el
## nivel al que sube, su descripción y lo que mejora. Se pulsa entera.

## Alto del icono.
const ICON_HEIGHT := 72.0

var option: LevelUpOption


func _init(offered: LevelUpOption) -> void:
	option = offered
	theme_type_variation = &"CardButton"
	custom_minimum_size = Vector2(260.0, 340.0 + (ICON_HEIGHT if option.item.icon else 0.0))
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
	_label(column, option.item.kind_key(), &"StatGroupLabel")
	_label(column, option.item.name_key, &"HeaderLabel")
	var level_text := tr(&"LEVEL_UP_NEW") if option.is_new() else tr(&"LEVEL_UP_LEVEL") % [option.level - 1, option.level]
	_label(column, level_text, &"StatValueLabel")
	_label(column, option.item.description_key, &"StatBaseLabel")
	for modifier: StatModifier in option.modifiers():
		_label(column, ModifierFormat.describe(modifier), &"StatModifiedLabel")


func _label(column: VBoxContainer, text_value: String, variation: StringName) -> void:
	var label := Label.new()
	label.text = text_value
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
