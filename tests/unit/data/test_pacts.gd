extends GutTest
## Pactos de data/pacts: cada uno con nombre y frase traducidos, con premio y maldición sobre stats que
## el jugador tiene (la maldición le quita, el premio le da), y el heraldo los ofrece todos.

const PACTS_DIR := "res://data/pacts"
const STRINGS_PATH := "res://data/i18n/strings.csv"
const HERALD := preload("res://data/pacts/herald.tres")
const PlayerScene := preload("res://entities/player/player.tscn")

var _keys := PackedStringArray()
var _pacts: Array[PactData] = []


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line.is_empty():
			_keys.append(line[0])
	_pacts.assign(ResourceDir.load_all(PACTS_DIR, PactData))


func test_texts_are_translated() -> void:
	assert_gt(_pacts.size(), HERALD.choices, "hay más pactos de los que se ofrecen a la vez")
	for pact: PactData in _pacts:
		assert_has(_keys, String(pact.name_key), "%s: falta su nombre" % pact.resource_path)
		assert_has(_keys, String(pact.flavor_key), "%s: falta su frase" % pact.resource_path)


func test_rewards_help_and_curses_hurt_the_player() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	for pact: PactData in _pacts:
		assert_false(pact.rewards.is_empty(), "%s: sin premio" % pact.resource_path)
		assert_false(pact.curses.is_empty(), "%s: sin maldición" % pact.resource_path)
		for modifier: StatModifier in pact.modifiers():
			assert_true(player.stats.has_stat(modifier.stat), "%s: «%s» no es una stat" % [pact.resource_path, modifier.stat])
		# La dificultad sube para mal; lo demás, al revés.
		for modifier: StatModifier in pact.rewards:
			assert_gt(_sign(modifier), 0.0, "%s: el premio %s quita" % [pact.resource_path, modifier.stat])
		for modifier: StatModifier in pact.curses:
			assert_lt(_sign(modifier), 0.0, "%s: la maldición %s da" % [pact.resource_path, modifier.stat])


func test_the_herald_offers_them_all() -> void:
	assert_eq(HERALD.pacts.size(), _pacts.size())
	for pact: PactData in _pacts:
		assert_has(HERALD.pacts, pact, "%s: el heraldo no lo ofrece" % pact.resource_path)
	assert_gt(HERALD.every_kills, 0)
	assert_lt(HERALD.min_distance, HERALD.max_distance)


func test_an_offer_has_different_pacts() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value: int in 20:
		rng.seed = seed_value
		var offer := HERALD.roll(rng)
		assert_eq(offer.size(), HERALD.choices)
		for index: int in offer.size():
			assert_eq(offer.count(offer[index]), 1, "sin repetir")


## Positivo si el modificador ayuda al jugador; negativo si le perjudica.
func _sign(modifier: StatModifier) -> float:
	var amount := modifier.value - 1.0 if modifier.kind == StatModifier.Kind.MULTIPLIER else modifier.value
	return -amount if modifier.stat == &"difficulty" else amount
