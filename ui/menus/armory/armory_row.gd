class_name ArmoryRow
extends PanelContainer
## Fila de un arma en el panel de la armería: nombre y nivel, descripción y, debajo a la derecha,
## botones para bajar y subir de nivel y para equiparla o quitarla. Solo avisa; el panel hace los
## cambios.

signal equip_toggled(data: WeaponData)
signal level_stepped(data: WeaponData, step: int)
## El ratón pasó por encima (para ver sus stats).
signal hovered(data: WeaponData)

var data: WeaponData

var _level: Label
var _level_down: Button
var _level_up: Button
var _equip: Button


func _init(weapon_data: WeaponData, alternate: bool) -> void:
	data = weapon_data
	theme_type_variation = &"StatRowAlt" if alternate else &"StatRow"
	mouse_filter = Control.MOUSE_FILTER_PASS
	var layout := VBoxContainer.new()
	layout.theme_type_variation = &"ArmoryRowLayout"
	add_child(layout)
	layout.add_child(_header())
	var description := Label.new()
	description.theme_type_variation = &"StatBaseLabel"
	description.text = data.description_key
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(description)
	var buttons := HBoxContainer.new()
	buttons.theme_type_variation = &"ArmoryRowButtons"
	buttons.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(buttons)
	_level_down = _button(buttons, &"ARMORY_LEVEL_DOWN", _emit_level_step.bind(-1))
	_level_up = _button(buttons, &"ARMORY_LEVEL_UP", _emit_level_step.bind(1))
	_equip = _button(buttons, &"ARMORY_EQUIP", _emit_equip_toggled)
	_equip.custom_minimum_size.x = 120.0
	mouse_entered.connect(_emit_hovered)


## Muestra el estado de [param weapon] (la que lleva el jugador de este tipo, o [code]null[/code]).
func refresh(weapon: Weapon) -> void:
	var equipped := weapon != null
	if equipped:
		_level.text = tr(&"ARMORY_LEVEL") % [weapon.level, data.max_level()]
	else:
		_level.text = tr(&"ARMORY_NOT_EQUIPPED")
	_level_down.disabled = not equipped or weapon.level <= 1
	_level_up.disabled = not equipped or weapon.level >= data.max_level()
	_equip.text = &"ARMORY_REMOVE" if equipped else &"ARMORY_EQUIP"


## Nombre a la izquierda y nivel a la derecha.
func _header() -> HBoxContainer:
	var header := HBoxContainer.new()
	var title := Label.new()
	title.theme_type_variation = &"StatNameLabel"
	title.text = data.name_key
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_level = Label.new()
	_level.theme_type_variation = &"StatValueLabel"
	header.add_child(_level)
	return header


func _button(parent: Control, text_key: StringName, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"SmallButton"
	button.text = text_key
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Sin foco: Espacio (saltar) no debe pulsar botones del panel.
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button


func _emit_level_step(step: int) -> void:
	level_stepped.emit(data, step)


func _emit_equip_toggled() -> void:
	equip_toggled.emit(data)


func _emit_hovered() -> void:
	hovered.emit(data)
