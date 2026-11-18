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
	for source: Resource in [OffenseData.new(), HealthData.new(), MovementData.new(), StaminaData.new(), ProgressionData.new()]:
		stats.sources.append(source)
	add_child_autofree(stats)
	_inventory = PassiveInventory.new()
	_inventory.stats = stats
	add_child_autofree(_inventory)
	_panel = PanelScene.instantiate() as ItemChoicePanel
	_panel.inventory = _inventory
	add_child_autofree(_panel)


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
