extends GutTest
## Elegir objeto: se abre al ofrecerse, pausa y enseña una carta por objeto (borde y rareza de su
## color); el elegido va al inventario y el juego sigue.

const PanelScene := preload("res://ui/menus/item_choice/item_choice_panel.tscn")
const HORSESHOE := preload("res://data/items/horseshoe.tres")
const TORCH := preload("res://data/items/torch.tres")
const EXCALIBRO := preload("res://data/items/excalibro.tres")

var _panel: ItemChoicePanel
var _inventory: PassiveInventory


func before_each() -> void:
	var stats := StatsComponent.new()
	for source: Resource in [OffenseData.new(), HealthData.new(), MovementData.new(), StaminaData.new(), ProgressionData.new(), MovementSynergyData.new()]:
		stats.sources.append(source)
	add_child_autofree(stats)
	_inventory = PassiveInventory.new()
	_inventory.stats = stats
	add_child_autofree(_inventory)
	_panel = PanelScene.instantiate() as ItemChoicePanel
	_panel.inventory = _inventory
	add_child_autofree(_panel)


func test_each_card_says_how_the_stats_change() -> void:
	EventBus.item_choice_offered.emit([EXCALIBRO] as Array[PassiveItemData])
	var card := _panel.get_cards()[0]
	var expected := ModifierFormat.describe_changes(EXCALIBRO.stat_modifiers, _inventory.stats)
	var shown := PackedStringArray()
	for label: Node in card.find_children("*", "Label", true, false):
		if (label as Label).theme_type_variation == &"StatModifiedLabel":
			shown.append((label as Label).text)
	assert_eq(shown.size(), EXCALIBRO.stat_modifiers.size())
	assert_eq(shown, expected, "cada stat con el valor de ahora y el que queda")
	assert_string_contains(shown[0], " → ")


func after_each() -> void:
	get_tree().paused = false


func test_shows_the_offer_and_gives_the_chosen_one() -> void:
	EventBus.item_choice_offered.emit([HORSESHOE, TORCH, EXCALIBRO] as Array[PassiveItemData])
	assert_true(_panel.is_open())
	assert_true(get_tree().paused)
	var cards := _panel.get_cards()
	assert_eq(cards.size(), 3)
	assert_same(cards[2].item, EXCALIBRO)
	cards[2].pressed.emit()
	assert_false(_panel.is_open())
	assert_false(get_tree().paused)
	assert_eq(_inventory.get_items(), [EXCALIBRO] as Array[PassiveItemData])


func test_reroll_costs_gold_more_each_time_and_brings_other_items() -> void:
	var wallet := WalletComponent.new()
	add_child_autofree(wallet)
	_panel.wallet = wallet
	var first := _panel.reroll_cost
	var second := roundi(_panel.reroll_cost * _panel.reroll_growth)
	wallet.add(float(first + second))
	EventBus.item_choice_offered.emit([HORSESHOE, TORCH, EXCALIBRO] as Array[PassiveItemData])
	assert_eq(_panel.current_reroll_cost(), first)
	assert_true(_panel.can_reroll())
	assert_true(_panel.reroll())
	var cards := _panel.get_cards()
	assert_eq(cards.size(), 3, "otros tres")
	for card: ItemChoiceCard in cards:
		assert_false([HORSESHOE, TORCH, EXCALIBRO].has(card.item), "distintos de los de antes")
	assert_eq(_panel.current_reroll_cost(), second, "más caro")
	assert_true(_panel.reroll())
	assert_false(_panel.can_reroll(), "sin oro, no")
	assert_false(_panel.reroll())
