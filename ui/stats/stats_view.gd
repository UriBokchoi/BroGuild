class_name StatsView
extends VBoxContainer
## Lista de las stats de un [StatsComponent]: agrupadas como en sus datos
## ([code]@export_group[/code]), con nombre traducido, unidad y filas alternas. Las que cambian
## por mejoras o maldiciones se resaltan con su valor base al lado. Una stat nueva aparece sola;
## solo necesita su traducción ([code]STAT_<NOMBRE>[/code] en data/i18n).

var _stats: StatsComponent
var _rows: Dictionary[StringName, StatRow] = {}


## Construye la lista para [param stats]. Se puede volver a llamar con otro componente.
func show_stats(stats: StatsComponent) -> void:
	_clear()
	_stats = stats
	var row_index := 0
	# El encabezado se pone con la primera stat del grupo: los Resources traen grupos propios
	# («Resource») sin stats.
	var pending_group := ""
	for source: Resource in stats.sources:
		for property: Dictionary in source.get_property_list():
			var usage: int = property["usage"]
			var property_name: String = property["name"]
			if usage & PROPERTY_USAGE_GROUP:
				pending_group = property_name
			elif stats.has_stat(property_name):
				if not pending_group.is_empty():
					_add_group(pending_group)
					pending_group = ""
					row_index = 0
				_add_row(property, row_index)
				row_index += 1
	refresh()


## Actualiza los valores (al abrir el menú, tras una mejora…).
func refresh() -> void:
	for stat: StringName in _rows:
		_rows[stat].show_value(_stats.get_value(stat), _stats.get_base(stat))


## Stats que muestra, en orden.
func shown_stats() -> Array[StringName]:
	var stats: Array[StringName] = []
	stats.assign(_rows.keys())
	return stats


## ¿Se muestra [param stat] resaltada (distinta de su base)?
func is_highlighted(stat: StringName) -> bool:
	return _rows.has(stat) and _rows[stat].modified


func _clear() -> void:
	for child: Node in get_children():
		child.queue_free()
	_rows.clear()


func _add_group(group: String) -> void:
	var label := Label.new()
	label.text = StatFormat.group_key(group)
	label.theme_type_variation = &"StatGroupLabel"
	label.uppercase = true
	add_child(label)


func _add_row(property: Dictionary, index: int) -> void:
	var row := StatRow.new(property)
	row.theme_type_variation = &"StatRow" if index % 2 == 0 else &"StatRowAlt"
	add_child(row)
	var stat: StringName = property["name"]
	_rows[stat] = row


## Fila de una stat: nombre a la izquierda; valor (y base si está modificada) a la derecha.
class StatRow:
	extends PanelContainer

	## El valor mostrado es distinto de la base.
	var modified: bool = false
	var _property: Dictionary
	var _value: Label
	var _base: Label

	func _init(property: Dictionary) -> void:
		_property = property
		var layout := HBoxContainer.new()
		add_child(layout)
		var stat_name := Label.new()
		var stat: StringName = property["name"]
		stat_name.text = StatFormat.name_key(stat)
		stat_name.theme_type_variation = &"StatNameLabel"
		stat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layout.add_child(stat_name)
		_base = _fixed_label(&"StatBaseLabel")
		_base.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		layout.add_child(_base)
		_value = _fixed_label(&"StatValueLabel")
		layout.add_child(_value)

	## Muestra [param value]; si no es la base, lo resalta y enseña la base.
	func show_value(value: float, base: float) -> void:
		modified = not is_equal_approx(value, base)
		_value.text = StatFormat.format(value, _property)
		_value.theme_type_variation = &"StatModifiedLabel" if modified else &"StatValueLabel"
		_base.visible = modified
		_base.text = tr(&"STAT_BASE") % StatFormat.format(base, _property)

	## Etiqueta para números: no se traduce, porque su texto ya viene formateado.
	func _fixed_label(variation: StringName) -> Label:
		var label := Label.new()
		label.theme_type_variation = variation
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		return label
