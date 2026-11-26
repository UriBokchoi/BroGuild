class_name UpgradeRow
extends PanelContainer
## Una mejora permanente en la pestaña «Mejoras»: icono, nombre y lo que hace, su nivel («Nivel 2/5»),
## lo que suma ahora y con el siguiente («+2 % → +3 %») y el botón de comprar con su precio. Avisa al
## pulsarlo (buy_pressed); comprar lo hace el panel.

## Se pulsó «Comprar».
signal buy_pressed(upgrade: MetaUpgradeData)

## Lado del icono.
const ICON_SIZE := 44.0

var upgrade: MetaUpgradeData

var _level: Label
var _value: Label
var _buy: Button


func _init(data: MetaUpgradeData, alternate: bool) -> void:
	upgrade = data
	theme_type_variation = &"StatRowAlt" if alternate else &"StatRow"
	var layout := HBoxContainer.new()
	layout.theme_type_variation = &"CardRow"
	add_child(layout)
	var icon := TextureRect.new()
	icon.texture = data.icon
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layout.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(text)
	text.add_child(_label(data.name_key, &"StatNameLabel"))
	var description := _label(data.description_key, &"StatBaseLabel")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(description)
	_level = _label(&"", &"StatBaseLabel")
	text.add_child(_level)
	_value = _label(&"", &"StatValueLabel")
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	layout.add_child(_value)
	_buy = Button.new()
	_buy.theme_type_variation = &"SmallButton"
	_buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_buy.custom_minimum_size.x = 150.0
	_buy.pressed.connect(func() -> void: buy_pressed.emit(upgrade))
	layout.add_child(_buy)


## Lo pinta con el nivel comprado en [param profile] y si le llegan las monedas.
func refresh(profile: PlayerProfile) -> void:
	var level := profile.level_of(upgrade.id)
	var maxed := level >= upgrade.max_level()
	_level.text = tr(&"UPGRADES_LEVEL") % [level, upgrade.max_level()]
	if maxed:
		_value.text = upgrade.value_text(level)
		_buy.text = tr(&"UPGRADES_MAXED")
	else:
		var now := upgrade.value_text(level) if level > 0 else tr(&"UPGRADES_NONE")
		_value.text = tr(&"UPGRADES_NEXT") % [now, upgrade.value_text(level + 1)]
		_buy.text = tr(&"UPGRADES_BUY") % upgrade.cost_of(level + 1)
	_buy.disabled = not profile.can_buy(upgrade)


## El botón de comprar (tests y foco).
func get_buy_button() -> Button:
	return _buy


## Lo que suma ahora y con el siguiente, como se ve.
func get_value_text() -> String:
	return _value.text


func _label(key: StringName, variation: StringName) -> Label:
	var label := Label.new()
	label.text = key
	label.theme_type_variation = variation
	return label
