extends GutTest
## Personajes en el jugador: la base de stats del personaje, su arma inicial, su pasiva y su aspecto;
## cambiar de personaje en el momento quita lo del anterior; RunState guarda la elección.

const PlayerScene := preload("res://entities/player/player.tscn")
const WARRIOR := preload("res://data/characters/warrior.tres")
const MAGE := preload("res://data/characters/mage.tres")
const ROGUE := preload("res://data/characters/rogue.tres")

var _player: Player


func before_each() -> void:
	RunState.character = null
	_player = _make_player(WARRIOR)


func after_each() -> void:
	# La elección sobrevive a recargar el nivel: que no pase de un test a otro.
	RunState.character = null


func test_starts_with_its_character() -> void:
	var neutral := _make_player(null)
	assert_eq(_player.health.get_maximum(), neutral.health.get_maximum() + _flat(WARRIOR, &"max_health"))
	assert_eq(_player.health.get_current(), _player.health.get_maximum(), "con la vida llena")
	assert_true(_player.weapons.has(WARRIOR.starting_weapon))
	assert_true(_player.passive is EndurancePassive)


func test_its_model_wears_its_look() -> void:
	assert_eq(_player.model.get_color(), WARRIOR.color)
	assert_eq(_player.model.get_pieces().size(), WARRIOR.attachments.size(), "espada y escudo")


func test_character_differences_are_base_not_upgrades() -> void:
	assert_eq(_player.stats.get_base(&"max_health"), _player.stats.get_value(&"max_health"))


func test_changing_character_swaps_everything() -> void:
	var neutral := _make_player(null)
	_player.set_character(MAGE)
	await wait_process_frames(1)
	assert_eq(_player.health.get_maximum(), neutral.health.get_maximum() + _flat(MAGE, &"max_health"))
	assert_eq(_player.health.get_current(), _player.health.get_maximum())
	assert_false(_player.weapons.has(WARRIOR.starting_weapon), "sin la espada del Guerrero")
	assert_true(_player.weapons.has(MAGE.starting_weapon))
	assert_true(_player.passive is ArcaneEchoPassive)
	assert_eq(_player.stats.get_value(&"armor"), neutral.stats.get_value(&"armor"), "sin su defensa")
	assert_same(RunState.character, MAGE, "la elección se guarda")
	assert_eq(_player.model.get_color(), MAGE.color, "con el color del Mago")
	assert_eq(_player.model.get_pieces().size(), MAGE.attachments.size(), "bastón y sombrero")


func test_the_chosen_character_wins_over_the_default() -> void:
	RunState.character = ROGUE
	var player := _make_player(WARRIOR)
	assert_same(player.character, ROGUE)
	assert_true(player.weapons.has(ROGUE.starting_weapon))


func test_the_rogue_has_more_stamina_and_air_jumps() -> void:
	var neutral := _make_player(null)
	var rogue := _make_player(ROGUE)
	assert_gt(rogue.stamina.get_max_charges(), neutral.stamina.get_max_charges())
	assert_gt(rogue.stats.get_value(&"air_jumps"), neutral.stats.get_value(&"air_jumps"))


func _make_player(character: CharacterData) -> Player:
	var player := PlayerScene.instantiate() as Player
	player.character = character
	add_child_autofree(player)
	return player


## Suma de los modificadores FLAT de [param stat] en [param character].
func _flat(character: CharacterData, stat: StringName) -> float:
	var total := 0.0
	for modifier: StatModifier in character.stat_modifiers:
		if modifier.stat == stat and modifier.kind == StatModifier.Kind.FLAT:
			total += modifier.value
	return total
