extends GutTest
## Pasivas de los personajes con el jugador de verdad: cada inicial gana una stat por nivel (Veterano,
## daño; Expansión arcana, área; Letal, crítico; Devoción, vida; Maleficio, daño crítico), que se va con
## la pasiva; el planeo del Mago; y la Furia del Bárbaro, que lo salva una vez y lo enfurece 10 s.

const PlayerScene := preload("res://entities/player/player.tscn")
const WARRIOR := preload("res://data/characters/warrior.tres")
const MAGE := preload("res://data/characters/mage.tres")
const ROGUE := preload("res://data/characters/rogue.tres")
const PALADIN := preload("res://data/characters/paladin.tres")
const BARBARIAN := preload("res://data/characters/barbarian.tres")
const WARLOCK := preload("res://data/characters/warlock.tres")

var _player: Player


func before_each() -> void:
	RunState.character = null
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)


func after_each() -> void:
	RunState.character = null
	Input.action_release(InputActions.JUMP)


func test_each_starting_character_grows_a_stat_per_level() -> void:
	var expected_stats: Dictionary[CharacterData, StringName] = {
		WARRIOR: &"damage", MAGE: &"area", ROGUE: &"crit_chance",
	}
	for character: CharacterData in expected_stats:
		var player := PlayerScene.instantiate() as Player
		add_child_autofree(player)
		player.set_character(character)
		var passive := player.passive as LevelStatPassive
		assert_eq(passive.stat, expected_stats[character])
		var at_level_1 := player.stats.get_value(passive.stat)
		player.experience.add(player.experience.needed() + player.experience.data.needed_for(2))
		assert_eq(player.experience.get_level(), 3)
		var bonus := passive.bonus_at(3)
		assert_gt(bonus, 0.0)
		var expected := at_level_1 + bonus if passive.kind == StatModifier.Kind.FLAT else at_level_1 * (1.0 + bonus)
		assert_almost_eq(player.stats.get_value(passive.stat), expected, 0.001, "%s sube con el nivel" % passive.stat)


func test_the_bonus_goes_away_with_the_passive() -> void:
	_player.set_character(ROGUE)
	var passive := _player.passive as LevelStatPassive
	var stat := passive.stat
	var at_level_1 := _player.stats.get_value(stat)
	_player.experience.add(_player.experience.needed())
	assert_gt(_player.stats.get_value(stat), at_level_1)
	passive.free()
	assert_eq(_player.stats.get_value(stat), at_level_1)


func test_glide_caps_the_fall_while_holding_jump() -> void:
	_player.stats.add_modifier(StatModifier.create(&"glide_fall_speed", StatModifier.Kind.FLAT, 3.0), self)
	_player.position = Vector3(0.0, 50.0, 0.0)
	Input.action_press(InputActions.JUMP)
	await wait_physics_frames(60)
	assert_almost_eq(_player.velocity.y, -3.0, 0.05, "planea")
	Input.action_release(InputActions.JUMP)
	await wait_physics_frames(30)
	assert_lt(_player.velocity.y, -6.0, "suelta el salto y cae")


func test_the_paladin_and_the_warlock_grow_a_stat_per_level_too() -> void:
	var expected_stats: Dictionary[CharacterData, StringName] = {
		PALADIN: &"max_health", WARLOCK: &"crit_damage",
	}
	for character: CharacterData in expected_stats:
		var player := PlayerScene.instantiate() as Player
		add_child_autofree(player)
		player.set_character(character)
		var passive := player.passive as LevelStatPassive
		assert_eq(passive.stat, expected_stats[character])
		assert_gt(passive.bonus_at(3), 0.0)


func test_the_barbarian_fury_saves_him_once_and_angers_him() -> void:
	_player.set_character(BARBARIAN)
	var fury := _player.passive as FuryPassive
	assert_not_null(fury)
	var damage := _player.stats.get_value(&"damage")
	_player.health.take_damage(DamageInfo.create(100000.0))
	assert_false(_player.health.is_dead(), "no muere")
	assert_eq(_player.health.get_current(), 1.0, "se queda a 1")
	assert_true(fury.is_raging())
	assert_true(_player.model.is_glowing(), "rojo de rabia")
	assert_almost_eq(_player.stats.get_value(&"damage"), damage * fury.boost, 0.01, "+30 %")
	await wait_physics_frames(3)
	_player.health.take_damage(DamageInfo.create(100000.0))
	assert_false(_player.health.is_dead(), "mientras dura, no puede morir")
	await wait_seconds(fury.duration + 0.2)
	assert_false(fury.is_raging())
	assert_false(_player.model.is_glowing())
	assert_almost_eq(_player.stats.get_value(&"damage"), damage, 0.01, "vuelve a lo de antes")
	await wait_physics_frames(3)
	_player.health.take_damage(DamageInfo.create(100000.0))
	assert_true(_player.health.is_dead(), "la segunda vez, muere")
