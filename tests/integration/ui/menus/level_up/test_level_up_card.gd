extends GutTest
## Carta de subir de nivel: una mejora lleva el borde y el nombre del color de su rareza; un objeto
## nuevo, el estilo normal. En la ruleta, una mejora gira por las rarezas sin dejarse elegir ni enseñar
## lo que mejora, y se para en la suya (sola, o al momento si se pide); un objeto nuevo no gira.

const SWORD := preload("res://data/weapons/sword.tres")
const LEGENDARY := preload("res://data/rarities/legendary.tres")
const RARITIES := preload("res://data/rarities/rarities.tres")


func test_an_upgrade_card_wears_its_rarity_color() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var option := LevelUpOption.create_upgrade(SWORD, 2, SWORD.roll_upgrade(LEGENDARY, rng))
	var card := LevelUpCard.new(option)
	add_child_autofree(card)
	var box := card.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_eq(box.border_color, LEGENDARY.color)
	assert_true(_has_label(card, LEGENDARY.name_key), "dice su rareza")


func test_an_upgrade_says_how_much_each_stat_grows() -> void:
	var stats := StatsComponent.new()
	stats.sources.append(SWORD.stats)
	add_child_autofree(stats)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var option := LevelUpOption.create_upgrade(SWORD, 2, SWORD.roll_upgrade(LEGENDARY, rng))
	option.stats = stats
	var card := LevelUpCard.new(option)
	add_child_autofree(card)
	var first := option.modifiers()[0]
	var expected := "%s %s" % [tr(StatFormat.name_key(first.stat)), ModifierFormat.change(first.stat, stats, option.modifiers())]
	assert_string_contains(expected, " → ")
	assert_true(_has_label(card, expected), "la stat, el valor de ahora y el que queda")


func test_without_stats_a_card_only_says_what_it_does() -> void:
	var card := _upgrade_card()
	for line: String in ModifierFormat.describe_all(card.option.modifiers()):
		assert_true(_has_label(card, line), "lo que hace: %s" % line)


func test_a_new_item_card_keeps_the_normal_style() -> void:
	var card := LevelUpCard.new(LevelUpOption.create(SWORD, 1))
	add_child_autofree(card)
	assert_false(card.has_theme_stylebox_override(&"normal"))


func test_an_upgrade_spins_hidden_and_stops_on_its_rarity() -> void:
	var card := _upgrade_card()
	watch_signals(EventBus)
	card.spin(_wheel(), 0.3, 1)
	assert_true(card.is_spinning())
	assert_true(card.disabled, "no se puede elegir mientras gira")
	assert_false(_effects_visible(card), "no se ve lo que mejora")
	await wait_seconds(0.4)
	assert_false(card.is_spinning())
	assert_false(card.disabled)
	assert_true(_effects_visible(card))
	assert_eq((card.get_theme_stylebox(&"normal") as StyleBoxFlat).border_color, LEGENDARY.color)
	assert_signal_emitted(EventBus, "upgrade_spin_ticked", "tic-tic")
	assert_signal_emitted_with_parameters(EventBus, "upgrade_revealed", [LEGENDARY])


func test_stopping_reveals_at_once() -> void:
	var card := _upgrade_card()
	card.spin(_wheel(), 5.0, 3)
	card.stop_spin()
	assert_false(card.is_spinning())
	assert_true(_effects_visible(card))


func test_a_new_item_does_not_spin() -> void:
	var card := LevelUpCard.new(LevelUpOption.create(SWORD, 1))
	add_child_autofree(card)
	card.spin(_wheel(), 1.0, 2)
	assert_false(card.is_spinning())
	assert_false(card.disabled)


func _upgrade_card() -> LevelUpCard:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var card := LevelUpCard.new(LevelUpOption.create_upgrade(SWORD, 2, SWORD.roll_upgrade(LEGENDARY, rng)))
	add_child_autofree(card)
	return card


func _wheel() -> Array[Rarity]:
	var wheel: Array[Rarity] = []
	wheel.assign(RARITIES.entries)
	return wheel


## ¿Se ven las líneas de lo que mejora (las del estilo de mejora)?
func _effects_visible(card: Node) -> bool:
	for label: Node in card.find_children("*", "Label", true, false):
		if (label as Label).theme_type_variation == &"StatModifiedLabel":
			return (label as Label).modulate.a > 0.5
	return false


func _has_label(card: Node, text: String) -> bool:
	for label: Node in card.find_children("*", "Label", true, false):
		if (label as Label).text == text:
			return true
	return false
