extends GutTest
## Armas y runas del HUD: tantas ranuras como dice LevelUpData, las abiertas vacías y el resto
## cerradas; lo que lleva el jugador, con su nivel y en orden; al quitar algo, las demás se corren.
## Con el jugador de verdad, el arma de su personaje aparece sola.

const HudScene := preload("res://ui/hud/hud.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")
const LEVEL_UP := preload("res://data/progression/level_up.tres")
const WARRIOR := preload("res://data/characters/warrior.tres")
const SWORD := preload("res://data/weapons/sword.tres")
const DAGGER := preload("res://data/weapons/dagger.tres")
const VIGOR := preload("res://data/runes/vigor.tres")

var _bar: LoadoutBar


func before_each() -> void:
	RunState.character = null
	var hud := HudScene.instantiate()
	add_child_autofree(hud)
	_bar = hud.get_node(^"%LoadoutBar") as LoadoutBar


func after_each() -> void:
	RunState.character = null


func test_open_slots_are_empty_and_the_rest_locked() -> void:
	_bar.show_slots(2, 1)
	var weapons := _bar.get_weapon_slots()
	assert_eq(weapons.size(), LEVEL_UP.max_weapon_slots)
	assert_eq(_bar.get_rune_slots().size(), LEVEL_UP.max_rune_slots)
	assert_eq(weapons[1].get_content(), LoadoutSlot.Content.EMPTY)
	assert_eq(weapons[2].get_content(), LoadoutSlot.Content.LOCKED)
	assert_eq(_bar.get_rune_slots()[1].get_content(), LoadoutSlot.Content.LOCKED)


func test_never_more_open_slots_than_there_are() -> void:
	_bar.show_slots(99, 99)
	for slot: LoadoutSlot in _bar.get_weapon_slots() + _bar.get_rune_slots():
		assert_ne(slot.get_content(), LoadoutSlot.Content.LOCKED)


func test_items_fill_their_row_in_order_with_their_level() -> void:
	_bar.show_slots(2, 2)
	_bar.show_item(SWORD, 1)
	_bar.show_item(DAGGER, 3)
	_bar.show_item(VIGOR, 2)
	var weapons := _bar.get_weapon_slots()
	assert_same(weapons[0].get_item(), SWORD)
	assert_same(weapons[1].get_item(), DAGGER)
	assert_eq(weapons[1].get_level_text(), "3")
	assert_same(_bar.get_rune_slots()[0].get_item(), VIGOR, "las runas en su fila")


func test_the_max_level_says_so() -> void:
	_bar.show_slots(2, 2)
	_bar.show_item(SWORD, SWORD.max_level())
	assert_eq(_bar.get_weapon_slots()[0].get_level_text(), tr(&"LOADOUT_MAX"))


func test_removing_an_item_shifts_the_rest() -> void:
	_bar.show_slots(2, 2)
	_bar.show_item(SWORD, 1)
	_bar.show_item(DAGGER, 1)
	_bar.show_item(SWORD, 0)
	var weapons := _bar.get_weapon_slots()
	assert_same(weapons[0].get_item(), DAGGER)
	assert_eq(weapons[1].get_content(), LoadoutSlot.Content.EMPTY)


func test_follows_the_real_player() -> void:
	var player := PlayerScene.instantiate() as Player
	player.character = WARRIOR
	add_child_autofree(player)
	var weapons := _bar.get_weapon_slots()
	assert_same(weapons[0].get_item(), WARRIOR.starting_weapon, "el arma de su personaje")
	assert_eq(weapons[player.stats.get_int(&"weapon_slots")].get_content(), LoadoutSlot.Content.LOCKED)
	player.weapons.get_weapon(WARRIOR.starting_weapon).set_level(2)
	assert_eq(weapons[0].get_level_text(), "2", "sube con el arma")
	player.runes.add(VIGOR)
	assert_same(_bar.get_rune_slots()[0].get_item(), VIGOR)
	var extra := StatModifier.new()
	extra.stat = &"weapon_slots"
	extra.value = 1.0
	player.stats.add_modifier(extra, self)
	assert_eq(weapons[2].get_content(), LoadoutSlot.Content.EMPTY, "una ranura desbloqueada")
