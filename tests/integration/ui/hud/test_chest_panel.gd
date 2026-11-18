extends GutTest
## Cofres en el HUD: al abrirse uno, la luz recorre las rarezas y se para en la del objeto, que se
## muestra con su nombre del color de su rareza, lo que hace (sus modificadores) y su frase; sin oro,
## solo el aviso. Debajo de las runas, los objetos que lleva, con las copias si son más de una.

const HudScene := preload("res://ui/hud/hud.tscn")
const RARITIES := preload("res://data/rarities/rarities.tres")
const CARD := preload("res://data/items/scratch_card.tres")
const CROWN := preload("res://data/items/bro_crown.tres")

var _hud: Node


func before_each() -> void:
	_hud = HudScene.instantiate()
	add_child_autofree(_hud)


func test_the_light_stops_on_the_item_rarity() -> void:
	var panel := _hud.get_node(^"%ChestPanel") as ChestPanel
	EventBus.item_revealed.emit(CROWN, 0.3)
	assert_true(panel.visible)
	assert_true(panel.is_revealing())
	await wait_seconds(0.4)
	assert_false(panel.is_revealing())
	assert_eq(panel.get_lit(), RARITIES.entries.find(CROWN.rarity), "en la mítica")
	var item_name := _hud.get_node(^"%ChestItemName") as Label
	assert_true((_hud.get_node(^"%ChestResult") as Control).visible)
	assert_eq(item_name.text, tr(CROWN.name_key))
	assert_eq(item_name.get_theme_color(&"font_color"), CROWN.rarity.color)
	var effects := (_hud.get_node(^"%ChestItemEffects") as Label).text
	var lines := ModifierFormat.describe_all(CROWN.stat_modifiers)
	assert_eq(lines.size(), CROWN.stat_modifiers.size())
	assert_eq(effects, "\n".join(lines), "lo que hace, de sus modificadores")
	assert_eq((_hud.get_node(^"%ChestItemDescription") as Label).text, tr(CROWN.description_key), "y su frase")


func test_without_gold_only_the_warning() -> void:
	var panel := _hud.get_node(^"%ChestPanel") as ChestPanel
	EventBus.chest_denied.emit(25)
	assert_true(panel.visible)
	var message := _hud.get_node(^"%ChestMessage") as Label
	assert_true(message.visible)
	assert_eq(message.text, tr(&"CHEST_NOT_ENOUGH_GOLD") % 25)
	assert_false((_hud.get_node(^"%ChestTiles") as Control).visible)


func test_the_items_show_under_the_runes_with_their_copies() -> void:
	var bar := _hud.get_node(^"%PassiveBar") as PassiveBar
	EventBus.player_passive_changed.emit(CARD, 1)
	EventBus.player_passive_changed.emit(CROWN, 1)
	EventBus.player_passive_changed.emit(CARD, 3)
	assert_eq(bar.get_shown(), [CARD.id, CROWN.id] as Array[StringName])
	assert_eq(bar.get_count_text(CARD), "×3")
	assert_eq(bar.get_count_text(CROWN), "", "una sola copia, sin número")
	EventBus.player_passive_changed.emit(CARD, 0)
	assert_eq(bar.get_shown(), [CROWN.id] as Array[StringName])
