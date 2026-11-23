class_name ItemChoiceCard
extends Button
## Carta de un objeto pasivo para elegir: su icono, su rareza (de su color, y el borde también), su
## nombre, su descripción y lo que mejora (con las stats del jugador, cómo queda cada una:
## «Daño 18 → 22»). Se pulsa entera.

## Alto del icono.
const ICON_HEIGHT := 72.0
## Alto de la carta sin icono y con una sola mejora, y de cada mejora de más.
const BASE_HEIGHT := 360.0
const LINE_HEIGHT := 28.0
const WIDTH := 260.0

var item: PassiveItemData


## [param stats]: las del jugador, para enseñar cuánto cambia cada una (sin ellas, solo lo que hace).
func _init(offered: PassiveItemData, stats: StatsComponent = null) -> void:
	item = offered
	theme_type_variation = &"CardButton"
	var effects := ModifierFormat.describe_changes(item.stat_modifiers, stats)
	var extra_lines := maxi(effects.size() - 1, 0)
	var height := BASE_HEIGHT + (ICON_HEIGHT if item.icon else 0.0) + LINE_HEIGHT * extra_lines
	custom_minimum_size = Vector2(WIDTH, height)
	focus_mode = Control.FOCUS_NONE
	var column := CardParts.column(self)
	if item.icon:
		CardParts.icon(column, item.icon, ICON_HEIGHT)
	if item.rarity:
		var rarity_label := CardParts.label(column, item.rarity.name_key, &"StatGroupLabel")
		rarity_label.add_theme_color_override(&"font_color", item.rarity.color)
	CardParts.label(column, item.name_key, &"HeaderLabel")
	CardParts.label(column, item.description_key, &"StatBaseLabel")
	for effect: String in effects:
		CardParts.label(column, effect, &"StatModifiedLabel")


func _ready() -> void:
	if item.rarity:
		CardParts.rarity_border(self, item.rarity)
