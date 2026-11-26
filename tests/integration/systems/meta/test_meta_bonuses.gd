extends GutTest
## Las mejoras permanentes en la partida, con el jugador de verdad: las de RunState.bonuses son base
## del jugador (no mejoras de la partida); los niveles de más dejan subir armas y runas por encima de
## su máximo de serie (y la elección al subir de nivel las sigue ofreciendo), y el HUD lo sabe.

const PlayerScene := preload("res://entities/player/player.tscn")
const UPGRADES := preload("res://data/meta/upgrades.tres")
const SWORD := preload("res://data/weapons/sword.tres")
const VIGOR := preload("res://data/runes/vigor.tres")

var _levels: Dictionary[StringName, int] = {}


func before_each() -> void:
	_levels = {}


func after_each() -> void:
	RunState.bonuses = null


func _player() -> Player:
	RunState.bonuses = UPGRADES.build_set(_levels)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	return player


func test_bonuses_are_part_of_the_base() -> void:
	_levels = {&"damage": 5, &"luck": 2, &"weapon_slots": 1}
	var player := _player()
	assert_almost_eq(player.stats.get_value(&"damage"), 105.0, 0.01, "+5 %")
	assert_almost_eq(player.stats.get_base(&"damage"), 105.0, 0.01, "como base")
	assert_eq(player.stats.get_value(&"luck"), 2.0)
	assert_eq(player.stats.get_int(&"weapon_slots"), 3)


func test_without_bonuses_nothing_changes() -> void:
	var player := _player()
	assert_eq(player.stats.get_value(&"damage"), 100.0)
	assert_eq(player.stats.get_int(&"weapon_level_bonus"), 0)


func test_weapons_go_past_their_cap() -> void:
	_levels = {&"weapon_level": 1}
	var player := _player()
	var sword := player.weapons.add(SWORD)
	assert_eq(sword.max_level(), SWORD.max_level() + 2)
	sword.set_level(99)
	assert_eq(sword.level, SWORD.max_level() + 2)


func test_runes_go_past_their_cap() -> void:
	_levels = {&"rune_level": 2}
	var player := _player()
	player.runes.set_level(VIGOR, 99)
	assert_eq(player.runes.get_level(VIGOR), VIGOR.max_level() + 10)


func test_the_level_up_still_offers_a_capped_item_with_extra_levels() -> void:
	_levels = {&"weapon_level": 1}
	var player := _player()
	var levels: Dictionary[StringName, int] = {&"sword": SWORD.max_level()}
	var catalog: Array[ItemData] = [SWORD]
	var rng := RandomNumberGenerator.new()
	var table := preload("res://data/progression/level_up.tres").rarities
	assert_eq(LevelUpOffer.build(catalog, levels, 3, 1, 1, table, rng).size(), 0, "sin stats, al máximo")
	var options := LevelUpOffer.build(catalog, levels, 3, 1, 1, table, rng, 0.0, player.stats)
	assert_eq(options.size(), 1, "con sus niveles de más, aún sube")


func test_the_hud_hears_the_raised_cap() -> void:
	_levels = {&"weapon_level": 1}
	var player := _player()
	watch_signals(EventBus)
	player.weapons.add(SWORD)
	assert_signal_emitted_with_parameters(EventBus, "player_item_changed",
		[SWORD, 1, SWORD.max_level() + 2])
