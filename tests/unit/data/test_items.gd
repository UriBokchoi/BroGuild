extends GutTest
## Objetos pasivos de data/items y el cofre de data/chests: cada objeto tiene id (el de su archivo),
## nombre y descripción traducidos, icono, rareza de la tabla y modificadores sobre stats que el
## jugador tiene; hay objetos de todas las rarezas, y el cofre los encuentra todos.

const ITEMS_DIR := "res://data/items"
const CHEST := preload("res://data/chests/chest.tres")
const RARITIES := preload("res://data/rarities/rarities.tres")
const PlayerScene := preload("res://entities/player/player.tscn")

var _items: Array[PassiveItemData] = []
var _stats: Array[StringName] = []


func before_all() -> void:
	_items.assign(ResourceDir.load_all(ITEMS_DIR, PassiveItemData))
	var player := PlayerScene.instantiate() as Player
	for source: Resource in player.stats.sources:
		for property: Dictionary in source.get_property_list():
			var property_name: String = property["name"]
			if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				_stats.append(StringName(property_name))
	player.free()


func test_there_are_items() -> void:
	assert_gte(_items.size(), 10)


func test_every_item_is_complete() -> void:
	for item: PassiveItemData in _items:
		var file := item.resource_path.get_file().get_basename()
		assert_eq(String(item.id), file, "%s: id distinto del archivo" % file)
		assert_ne(tr(item.name_key), String(item.name_key), "%s: nombre sin traducir" % file)
		assert_ne(tr(item.description_key), String(item.description_key), "%s: descripción sin traducir" % file)
		assert_not_null(item.icon, "%s: sin icono" % file)
		assert_not_null(item.rarity, "%s: sin rareza" % file)
		assert_has(RARITIES.entries, item.rarity, "%s: rareza fuera de la tabla" % file)
		assert_false(item.stat_modifiers.is_empty(), "%s: no hace nada" % file)
		for modifier: StatModifier in item.stat_modifiers:
			assert_has(_stats, modifier.stat, "%s: «%s» no es una stat del jugador" % [file, modifier.stat])


func test_descriptions_leave_the_numbers_to_the_modifiers() -> void:
	# Las cifras salen de los modificadores (en cofres y cartas): si estuvieran también en la frase,
	# se verían repetidas y mentirían al cambiar un valor.
	var digits := RegEx.create_from_string("\\d")
	for locale: String in TranslationServer.get_loaded_locales():
		var translation := TranslationServer.get_translation_object(locale)
		for item: PassiveItemData in _items:
			var text := String(translation.get_message(item.description_key))
			assert_ne(text, "", "%s (%s): sin frase" % [item.id, locale])
			assert_null(digits.search(text), "%s (%s): «%s» lleva cifras" % [item.id, locale, text])


func test_every_rarity_has_items() -> void:
	for entry: WeightedEntry in RARITIES.entries:
		var rarity := entry as Rarity
		var found := _items.any(func(item: PassiveItemData) -> bool: return item.rarity == rarity)
		assert_true(found, "ningún objeto %s" % rarity.id)


func test_the_chest_finds_every_item() -> void:
	assert_eq(CHEST.items.load_catalog().size(), _items.size())
	assert_same(CHEST.items.rarities, RARITIES)
	assert_gt(CHEST.cost_at(0.0, 0), 0)
	assert_gt(CHEST.reveal_time, 0.0)
