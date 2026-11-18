extends GutTest
## Pasivas de los personajes con el jugador de verdad: cada inicial gana una stat por nivel (Veterano,
## daño; Expansión arcana, área; Letal, crítico), que se va con la pasiva; y el planeo del Mago.

const PlayerScene := preload("res://entities/player/player.tscn")
const WARRIOR := preload("res://data/characters/warrior.tres")
const MAGE := preload("res://data/characters/mage.tres")
const ROGUE := preload("res://data/characters/rogue.tres")

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
