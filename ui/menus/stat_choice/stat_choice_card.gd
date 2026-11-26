class_name StatChoiceCard
extends Button
## La carta de una mejora de stats: su rareza (del color de la rareza, y el borde también), la stat,
## lo que suma y cómo queda («Daño 100 % → 108 %»). Se pulsa entera.

const WIDTH := 240.0
const HEIGHT := 260.0

var offer: StatOffer


## [param stats]: las del jugador, para enseñar cuánto cambia (sin ellas, solo lo que suma).
func _init(given: StatOffer, stats: StatsComponent = null) -> void:
	offer = given
	theme_type_variation = &"CardButton"
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	focus_mode = Control.FOCUS_NONE
	var column := CardParts.column(self)
	var rarity_label := CardParts.label(column, offer.rarity.name_key, &"StatGroupLabel")
	rarity_label.add_theme_color_override(&"font_color", offer.rarity.color)
	CardParts.label(column, StatFormat.name_key(offer.stat.stat), &"HeaderLabel")
	var modifier := offer.modifier()
	CardParts.label(column, ModifierFormat.describe(modifier), &"StatModifiedLabel")
	var modifiers: Array[StatModifier] = [modifier]
	var change := ModifierFormat.change(modifier.stat, stats, modifiers)
	if not change.is_empty():
		CardParts.label(column, change, &"StatValueLabel")
	CardParts.fit_height(self, column)


func _ready() -> void:
	CardParts.rarity_border(self, offer.rarity)
