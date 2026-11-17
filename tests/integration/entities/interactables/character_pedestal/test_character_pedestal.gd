extends GutTest
## Pedestal de personaje: su cartel dice el nombre, su modelo va vestido como el personaje y al
## interactuar el jugador pasa a ser ese personaje.

const PedestalScene := preload("res://entities/interactables/character_pedestal/character_pedestal.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")
const MAGE := preload("res://data/characters/mage.tres")

var _pedestal: CharacterPedestal


func before_each() -> void:
	RunState.character = null
	_pedestal = PedestalScene.instantiate() as CharacterPedestal
	_pedestal.character = MAGE
	add_child_autofree(_pedestal)


func after_each() -> void:
	RunState.character = null


func test_its_label_names_the_character() -> void:
	assert_eq(_pedestal.label.text, String(MAGE.name_key))


func test_interacting_makes_the_player_that_character() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	_pedestal.interactable.interact(player)
	assert_same(player.character, MAGE)
	assert_true(player.weapons.has(MAGE.starting_weapon))


func test_its_model_wears_the_character() -> void:
	assert_eq(_pedestal.model.get_color(), MAGE.color)
	assert_eq(_pedestal.model.get_pieces().size(), MAGE.attachments.size())
