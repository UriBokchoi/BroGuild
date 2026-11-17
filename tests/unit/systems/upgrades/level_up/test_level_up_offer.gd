extends GutTest
## LevelUpOffer: ofrece subir lo que ya lleva (sin pasar del máximo) y objetos nuevos solo si queda
## ranura abierta de su tipo; opciones distintas, como mucho las pedidas, reproducibles con semilla.

const SWORD := preload("res://data/weapons/sword.tres")
const STRENGTH := preload("res://data/runes/strength.tres")
const VIGOR := preload("res://data/runes/vigor.tres")
const HASTE := preload("res://data/runes/haste.tres")

const CHOICES := 3
const WEAPON_SLOTS := 1
const RUNE_SLOTS := 2

var _catalog: Array[ItemData] = []
var _rng: RandomNumberGenerator


func before_each() -> void:
	_catalog = [SWORD, STRENGTH, VIGOR, HASTE]
	_rng = RandomNumberGenerator.new()
	_rng.seed = 11


func test_offers_distinct_options_up_to_the_choices() -> void:
	var options := LevelUpOffer.build(_catalog, {}, CHOICES, WEAPON_SLOTS, RUNE_SLOTS, _rng)
	assert_eq(options.size(), 3)
	var ids: Array[StringName] = []
	for option: LevelUpOption in options:
		assert_does_not_have(ids, option.item.id)
		ids.append(option.item.id)
		assert_true(option.is_new())


func test_owned_items_are_offered_one_level_up() -> void:
	var options := LevelUpOffer.build([SWORD] as Array[ItemData], {&"sword": 2}, CHOICES, WEAPON_SLOTS, RUNE_SLOTS, _rng)
	assert_eq(options.size(), 1)
	assert_eq(options[0].level, 3)
	assert_eq(options[0].modifiers(), SWORD.level_modifiers(3))


func test_maxed_items_are_not_offered() -> void:
	var levels: Dictionary[StringName, int] = {&"sword": SWORD.max_level()}
	assert_eq(LevelUpOffer.build([SWORD] as Array[ItemData], levels, CHOICES, WEAPON_SLOTS, RUNE_SLOTS, _rng).size(), 0)


func test_no_new_items_when_their_slots_are_full() -> void:
	# Dos runas (el máximo): Prisa no puede salir, pero las que lleva sí.
	var levels: Dictionary[StringName, int] = {&"strength": 1, &"vigor": 1}
	for _try: int in 20:
		for option: LevelUpOption in LevelUpOffer.build(_catalog, levels, CHOICES, WEAPON_SLOTS, RUNE_SLOTS, _rng):
			assert_ne(option.item.id, &"haste")


func test_same_seed_same_offer() -> void:
	var first := LevelUpOffer.build(_catalog, {}, CHOICES, WEAPON_SLOTS, RUNE_SLOTS, _rng)
	var again := RandomNumberGenerator.new()
	again.seed = 11
	var second := LevelUpOffer.build(_catalog, {}, CHOICES, WEAPON_SLOTS, RUNE_SLOTS, again)
	for index: int in first.size():
		assert_eq(first[index].item.id, second[index].item.id)


func test_more_open_slots_let_new_items_in() -> void:
	# Con una tercera ranura de runas abierta, Prisa ya puede salir.
	var levels: Dictionary[StringName, int] = {&"strength": 1, &"vigor": 1}
	var ids: Array[StringName] = []
	for _try: int in 20:
		for option: LevelUpOption in LevelUpOffer.build(_catalog, levels, CHOICES, WEAPON_SLOTS, RUNE_SLOTS + 1, _rng):
			ids.append(option.item.id)
	assert_has(ids, &"haste")
