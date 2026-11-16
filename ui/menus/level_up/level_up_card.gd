class_name LevelUpCard
extends Button
## Carta de una opción al subir de nivel: qué es (arma o runa), su nombre, «Nuevo» o el nivel al
## que sube, su descripción y lo que mejora. Se pulsa entera.

var option: LevelUpOption


func _init(offered: LevelUpOption) -> void:
	option = offered
	theme_type_variation = &"CardButton"
	custom_minimum_size = Vector2(260.0, 340.0)
	focus_mode = Control.FOCUS_NONE
	var column := VBoxContainer.new()
	column.theme_type_variation = &"CardColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	add_child(column)
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
