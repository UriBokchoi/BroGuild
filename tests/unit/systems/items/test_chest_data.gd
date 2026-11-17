extends GutTest
## ChestData: el coste sube con la dificultad y con cada cofre abierto; lo que sale es de la rareza
## tirada (si no hay de esa, de la de debajo), la Suerte hace salir más de las altas y con la misma
## semilla sale lo mismo.

const RARITIES := preload("res://data/rarities/rarities.tres")
const COMMON := preload("res://data/rarities/common.tres")
const RARE := preload("res://data/rarities/rare.tres")
const MYTHIC := preload("res://data/rarities/mythic.tres")

var _rng: RandomNumberGenerator


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 5


func test_cost_grows_with_difficulty_and_with_each_chest() -> void:
	var data := _data()
	assert_eq(data.cost_at(0.0, 0), 20)
	assert_eq(data.cost_at(5.0, 0), 40, "+4 por punto de dificultad")
	assert_eq(data.cost_at(0.0, 2), 45, "×1,5 por cofre abierto")


func test_the_item_has_the_rolled_rarity() -> void:
	var common := _item(&"common", COMMON)
	var mythic := _item(&"mythic", MYTHIC)
	var data := _data()
	var mythics := 0
	for _roll: int in 2000:
		var item := data.roll([common, mythic] as Array[PassiveItemData], 0.0, _rng)
		if item == mythic:
			mythics += 1
	# Rara, improbable y de leyenda no tienen objetos: caen a la común (la de debajo).
	assert_between(mythics, 5, 50, "≈ 1 % de míticas")


func test_without_items_of_a_rarity_it_falls_to_the_one_below() -> void:
	var rare := _item(&"rare", RARE)
	var data := _data()
	data.rarities = _only(MYTHIC)
	assert_same(data.roll([rare] as Array[PassiveItemData], 0.0, _rng), rare, "mítica → la rara de debajo")
	data.rarities = _only(COMMON)
	assert_same(data.roll([rare] as Array[PassiveItemData], 0.0, _rng), rare, "nada debajo → cualquiera")
	assert_null(data.roll([] as Array[PassiveItemData], 0.0, _rng))


func test_luck_brings_rarer_items() -> void:
	var common := _item(&"common", COMMON)
	var rare := _item(&"rare", RARE)
	var catalog: Array[PassiveItemData] = [common, rare]
	var data := _data()
	var without := 0
	var with_luck := 0
	for _roll: int in 2000:
		if data.roll(catalog, 0.0, _rng) == rare:
			without += 1
		if data.roll(catalog, 100.0, _rng) == rare:
			with_luck += 1
	assert_gt(with_luck, without + 300)


func test_same_seed_same_item() -> void:
	var catalog: Array[PassiveItemData] = [_item(&"a", COMMON), _item(&"b", COMMON), _item(&"c", RARE)]
	var data := _data()
	var again := RandomNumberGenerator.new()
	again.seed = 5
	for _roll: int in 30:
		assert_same(data.roll(catalog, 10.0, _rng), data.roll(catalog, 10.0, again))


func _data() -> ChestData:
	var data := ChestData.new()
	data.rarities = RARITIES
	data.base_cost = 20.0
	data.cost_per_difficulty = 4.0
	data.cost_growth = 1.5
	return data


func _only(rarity: Rarity) -> WeightedTable:
	# La misma tabla, pero solo [param rarity] con peso: así se sabe qué sale.
	var table := WeightedTable.new()
	for entry: WeightedEntry in RARITIES.entries:
		var copy := entry.duplicate() as Rarity
		copy.weight = 1.0 if entry == rarity else 0.0
		table.entries.append(copy)
	return table


func _item(id: StringName, rarity: Rarity) -> PassiveItemData:
	var item := PassiveItemData.new()
	item.id = id
	item.rarity = rarity
	return item
