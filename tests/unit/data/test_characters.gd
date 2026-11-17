extends GutTest
## Personajes de data/characters: están el Guerrero, el Mago y el Pícaro; cada uno es un
## CharacterData con nombre, descripción y pasiva traducidos, un arma inicial, una pasiva que es un
## CharacterPassive, sus diferencias apuntan a stats que el jugador tiene y sus piezas van a puntos
## del modelo que existen.

const CHARACTERS_DIR := "res://data/characters"
const STRINGS_PATH := "res://data/i18n/strings.csv"
const PlayerScene := preload("res://entities/player/player.tscn")
const ModelScene := preload("res://entities/player/characters/model/character_model.tscn")

var _keys := PackedStringArray()
var _characters: Array[CharacterData] = []


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line.is_empty():
			_keys.append(line[0])
	for resource: Resource in ResourceDir.load_all(CHARACTERS_DIR, CharacterData):
		_characters.append(resource as CharacterData)


func test_the_three_starting_characters_exist() -> void:
	var names: Array[StringName] = []
	for character: CharacterData in _characters:
		names.append(character.name_key)
	for expected: StringName in [&"CHARACTER_WARRIOR_NAME", &"CHARACTER_MAGE_NAME", &"CHARACTER_ROGUE_NAME"]:
		assert_has(names, expected)


func test_every_character_is_complete() -> void:
	for character: CharacterData in _characters:
		var label := character.resource_path.get_file()
		for key: StringName in [character.name_key, character.description_key, character.passive_name_key, character.passive_description_key]:
			assert_has(_keys, String(key), "%s: falta «%s»" % [label, key])
		assert_not_null(character.starting_weapon, "%s: sin arma inicial" % label)
		assert_not_null(character.passive, "%s: sin pasiva" % label)
		if character.passive:
			var passive := character.passive.instantiate()
			assert_true(passive is CharacterPassive, "%s: su pasiva no es un CharacterPassive" % label)
			passive.free()


func test_every_character_changes_existing_stats() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	for character: CharacterData in _characters:
		for modifier: StatModifier in character.stat_modifiers:
			var label := character.resource_path.get_file()
			assert_true(player.stats.has_stat(modifier.stat), "%s: «%s» no es una stat" % [label, modifier.stat])


func test_every_piece_goes_to_an_existing_socket() -> void:
	var model := ModelScene.instantiate() as CharacterModel
	add_child_autofree(model)
	for character: CharacterData in _characters:
		var label := character.resource_path.get_file()
		assert_false(character.attachments.is_empty(), "%s: sin piezas" % label)
		for attachment: ModelAttachment in character.attachments:
			assert_not_null(attachment.scene, "%s: pieza sin escena" % label)
			assert_true(model.sockets.has_node(NodePath(String(attachment.socket))), "%s: no hay punto «%s»" % [label, attachment.socket])


func test_each_character_regenerates_a_little_its_own_way() -> void:
	var regens: Array[float] = []
	for character: CharacterData in _characters:
		var regen := 0.0
		for modifier: StatModifier in character.stat_modifiers:
			if modifier.stat == &"health_regen":
				regen += modifier.value
		assert_between(regen, 0.1, 2.0, "%s: un poco de regeneración" % character.resource_path.get_file())
		assert_does_not_have(regens, regen, "cada uno la suya")
		regens.append(regen)
