class_name LevelUpCard
extends Button
## Carta de una opción al subir de nivel: su icono, qué es (arma o runa), su nombre, «Nuevo» o el
## nivel al que sube, su descripción y lo que mejora. Las mejoras llevan su rareza: el borde de la
## carta y su nombre van del color de la rareza ([member Rarity.color]). Se pulsa entera.
##
## La ruleta ([method spin]): una carta de mejora gira por las rarezas, cada vez más despacio, y se
## para en la suya; mientras gira no se puede elegir ni se ve lo que mejora. Avisa de cada paso
## ([signal EventBus.upgrade_spin_ticked]) y de la rareza en la que cae
## ([signal EventBus.upgrade_revealed]), para el sonido.

## Alto del icono.
const ICON_HEIGHT := 72.0
## Alto de cada línea de más (rareza, mejoras de varias stats).
const LINE_HEIGHT := 28.0
## Cuánto crece la carta al pararse, y en cuántos segundos vuelve a su tamaño.
const REVEAL_POP := 1.06
const REVEAL_POP_TIME := 0.18

var option: LevelUpOption

var _rarity_label: Label
## Líneas de lo que mejora: ocultas mientras gira.
var _effects: Array[Label] = []
## Rarezas por las que gira, en orden.
var _wheel: Array[Rarity] = []
var _spin_time: float = 0.0
var _elapsed: float = 0.0
var _steps: int = 0
var _shown: int = -1
var _spinning: bool = false
var _pop: Tween


func _init(offered: LevelUpOption) -> void:
	option = offered
	theme_type_variation = &"CardButton"
	var extra_lines := maxi(option.modifiers().size() - 1, 0) + (1 if option.rarity() else 0)
	var height := 340.0 + (ICON_HEIGHT if option.item.icon else 0.0) + LINE_HEIGHT * extra_lines
	custom_minimum_size = Vector2(260.0, height)
	focus_mode = Control.FOCUS_NONE
	var column := CardParts.column(self)
	if option.item.icon:
		CardParts.icon(column, option.item.icon, ICON_HEIGHT)
	var rarity := option.rarity()
	if rarity:
		_rarity_label = CardParts.label(column, rarity.name_key, &"StatGroupLabel")
		_rarity_label.add_theme_color_override(&"font_color", rarity.color)
	CardParts.label(column, option.item.kind_key(), &"StatGroupLabel")
	CardParts.label(column, option.item.name_key, &"HeaderLabel")
	var level_text := tr(&"LEVEL_UP_NEW") if option.is_new() else tr(&"LEVEL_UP_LEVEL") % [option.level - 1, option.level]
	CardParts.label(column, level_text, &"StatValueLabel")
	CardParts.label(column, option.item.description_key, &"StatBaseLabel")
	for modifier: StatModifier in option.modifiers():
		_effects.append(CardParts.label(column, ModifierFormat.describe(modifier), &"StatModifiedLabel"))
	set_process(false)


func _ready() -> void:
	# Godot vuelve a activar _process al estar lista: solo gira si se lo han pedido.
	set_process(_spinning)
	var rarity := option.rarity()
	if rarity and not _spinning:
		CardParts.rarity_border(self, rarity)


func _exit_tree() -> void:
	if _pop:
		_pop.kill()


## Gira por [param wheel] (las rarezas en orden) durante [param seconds], dando [param loops]
## vueltas enteras antes de pararse en su rareza. Una carta sin rareza (un objeto nuevo) no gira.
func spin(wheel: Array[Rarity], seconds: float, loops: int) -> void:
	var rarity := option.rarity()
	var final := _index_of(wheel, rarity)
	if rarity == null or seconds <= 0.0 or final < 0:
		return
	_wheel = wheel
	_spin_time = seconds
	_elapsed = 0.0
	_steps = loops * wheel.size() + final
	_shown = -1
	_spinning = true
	disabled = true
	for line: Label in _effects:
		line.modulate.a = 0.0
	_show_rarity(wheel[0])
	set_process(true)


## ¿Sigue girando?
func is_spinning() -> bool:
	return _spinning


## Se para ya en su rareza.
func stop_spin() -> void:
	if _spinning:
		_reveal()


func _process(delta: float) -> void:
	if not _spinning:
		set_process(false)
		return
	_elapsed += delta
	var progress := clampf(_elapsed / _spin_time, 0.0, 1.0)
	# Frena al final: avanza rápido al principio y cada vez más despacio.
	var step := floori(_steps * (1.0 - pow(1.0 - progress, 2.0)))
	if step != _shown:
		_shown = step
		_show_rarity(_wheel[step % _wheel.size()])
		EventBus.upgrade_spin_ticked.emit()
	if progress >= 1.0:
		_reveal()


func _reveal() -> void:
	_spinning = false
	set_process(false)
	disabled = false
	var rarity := option.rarity()
	_show_rarity(rarity)
	for line: Label in _effects:
		line.modulate.a = 1.0
	pivot_offset = size / 2.0
	scale = Vector2.ONE * REVEAL_POP
	_pop = create_tween()
	_pop.tween_property(self, ^"scale", Vector2.ONE, REVEAL_POP_TIME)
	EventBus.upgrade_revealed.emit(rarity)


func _show_rarity(rarity: Rarity) -> void:
	_rarity_label.text = rarity.name_key
	_rarity_label.add_theme_color_override(&"font_color", rarity.color)
	if is_inside_tree():
		CardParts.rarity_border(self, rarity)


static func _index_of(wheel: Array[Rarity], rarity: Rarity) -> int:
	if rarity == null:
		return -1
	for index: int in wheel.size():
		if wheel[index].id == rarity.id:
			return index
	return -1
