extends GutTest
## Carta de subir de nivel: una mejora lleva el borde y el nombre del color de su rareza; un objeto
## nuevo, el estilo normal.

const SWORD := preload("res://data/weapons/sword.tres")
const LEGENDARY := preload("res://data/rarities/legendary.tres")


func test_an_upgrade_card_wears_its_rarity_color() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var option := LevelUpOption.create_upgrade(SWORD, 2, SWORD.roll_upgrade(LEGENDARY, rng))
	var card := LevelUpCard.new(option)
	add_child_autofree(card)
	var box := card.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_eq(box.border_color, LEGENDARY.color)
	assert_true(_has_label(card, LEGENDARY.name_key), "dice su rareza")


func test_a_new_item_card_keeps_the_normal_style() -> void:
	var card := LevelUpCard.new(LevelUpOption.create(SWORD, 1))
	add_child_autofree(card)
	assert_false(card.has_theme_stylebox_override(&"normal"))


func _has_label(card: Node, text: String) -> bool:
	for label: Node in card.find_children("*", "Label", true, false):
		if (label as Label).text == text:
			return true
	return false
