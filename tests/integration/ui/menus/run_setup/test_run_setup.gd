extends GutTest
## Selección de personaje y nivel: lista los personajes; al mirar uno, el modelo y la ficha son
## suyos; al elegirlo, salen los niveles (los que aún no existen, desactivados) y elegir uno pide
## jugar con ese personaje; «Volver» retrocede de los niveles a los personajes y de ahí al menú.

const SetupScene := preload("res://ui/menus/run_setup/run_setup.tscn")
const MAGE := preload("res://data/characters/mage.tres")
const ROGUE := preload("res://data/characters/rogue.tres")
const BROSQUE := preload("res://data/levels/brosque.tres")
const DUNGEON := preload("res://data/levels/dungeon.tres")

var _setup: RunSetup
var _played: Array = []


func before_each() -> void:
	RunState.character = null
	_played.clear()
	_setup = SetupScene.instantiate() as RunSetup
	add_child_autofree(_setup)
	_setup.play_requested.connect(func(character: CharacterData, level: LevelData) -> void: _played.append([character, level]))


func after_each() -> void:
	RunState.character = null


func test_lists_every_character() -> void:
	assert_eq((_setup.get_node(^"%CharacterList") as Node).get_child_count(), _setup.characters.size())


func test_looking_at_a_character_shows_its_model_and_sheet() -> void:
	_setup.show_character(MAGE)
	assert_same(_setup.get_shown(), MAGE)
	assert_eq(_setup.model.get_color(), MAGE.color)
	assert_eq((_setup.get_node(^"%CharacterName") as Label).text, String(MAGE.name_key))
	assert_eq((_setup.get_node(^"%WeaponName") as Label).text, String(MAGE.starting_weapon.name_key))
	assert_eq((_setup.get_node(^"%PassiveName") as Label).text, String(MAGE.passive_name_key))
	assert_eq((_setup.get_node(^"%CharacterStats") as Node).get_child_count(), MAGE.stat_modifiers.size())


func test_choosing_shows_the_levels_and_a_level_starts_the_run() -> void:
	_setup.choose(ROGUE)
	assert_true(_setup.is_choosing_level())
	_setup.play(DUNGEON)
	assert_eq(_played.size(), 0, "la Mazmorra aún no existe")
	_setup.play(BROSQUE)
	assert_eq(_played, [[ROGUE, BROSQUE]])


func test_levels_that_do_not_exist_yet_are_disabled() -> void:
	var buttons := (_setup.get_node(^"%LevelList") as Node).get_children()
	for index: int in buttons.size():
		assert_eq((buttons[index] as Button).disabled, not _setup.levels[index].is_available())


func test_back_goes_from_levels_to_characters_to_the_menu() -> void:
	watch_signals(_setup)
	_setup.choose(MAGE)
	_setup.back()
	assert_false(_setup.is_choosing_level())
	assert_signal_not_emitted(_setup, "back_requested")
	_setup.back()
	assert_signal_emitted(_setup, "back_requested")


func test_while_choosing_a_level_the_character_list_hides() -> void:
	var side := _setup.get_node(^"%Side") as Control
	assert_true(side.visible)
	_setup.choose(MAGE)
	assert_false(side.visible, "un solo «Volver», el de los niveles")
	_setup.back()
	assert_true(side.visible)
