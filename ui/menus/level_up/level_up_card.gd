class_name LevelUpCard
extends Button
## Carta de una opción al subir de nivel: su icono, qué es (arma o runa), su nombre, «Nuevo» o el
## nivel al que sube, su descripción y lo que mejora. Las mejoras llevan su rareza: el borde de la
## carta y su nombre van del color de la rareza ([member Rarity.color]). Se pulsa entera.

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
	var column := CardParts.column(self)
	if option.item.icon:
		CardParts.icon(column, option.item.icon, ICON_HEIGHT)
	var rarity := option.rarity()
	if rarity:
		var rarity_label := CardParts.label(column, rarity.name_key, &"StatGroupLabel")
		rarity_label.add_theme_color_override(&"font_color", rarity.color)
	CardParts.label(column, option.item.kind_key(), &"StatGroupLabel")
	CardParts.label(column, option.item.name_key, &"HeaderLabel")
	var level_text := tr(&"LEVEL_UP_NEW") if option.is_new() else tr(&"LEVEL_UP_LEVEL") % [option.level - 1, option.level]
	CardParts.label(column, level_text, &"StatValueLabel")
	CardParts.label(column, option.item.description_key, &"StatBaseLabel")
	for modifier: StatModifier in option.modifiers():
		CardParts.label(column, ModifierFormat.describe(modifier), &"StatModifiedLabel")


func _ready() -> void:
	var rarity := option.rarity()
	if rarity == null:
		return
	CardParts.rarity_border(self, rarity)

