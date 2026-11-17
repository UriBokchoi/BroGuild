extends GutTest
## Pasivas de los personajes con el jugador de verdad: Aguante (daño por enemigos cerca), Eco arcano
## (golpes extra cada tantos ataques), Letal (crítico por nivel) y el planeo del Mago.

const PlayerScene := preload("res://entities/player/player.tscn")
const DummyScene := preload("res://entities/enemies/target_dummy/target_dummy.tscn")
const ROGUE := preload("res://data/characters/rogue.tres")
const STAFF := preload("res://data/weapons/staff.tres")

var _player: Player


func before_each() -> void:
	RunState.character = null
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)


func after_each() -> void:
	RunState.character = null
	Input.action_release(InputActions.JUMP)


func test_endurance_adds_damage_per_enemy_nearby() -> void:
	var base := _player.stats.get_value(&"damage")
	var passive := _add_passive(_endurance()) as EndurancePassive
	_add_dummy(Vector3(2.0, 0.0, 0.0))
	_add_dummy(Vector3(-2.0, 0.0, 0.0))
	_add_dummy(Vector3(30.0, 0.0, 0.0))
	await wait_physics_frames(10)
	assert_eq(passive.get_count(), 2, "solo los de cerca")
	assert_almost_eq(_player.stats.get_value(&"damage"), base * 1.04, 0.01)


func test_endurance_bonus_goes_away_with_the_passive() -> void:
	var base := _player.stats.get_value(&"damage")
	var passive := _add_passive(_endurance())
	_add_dummy(Vector3(2.0, 0.0, 0.0))
	await wait_physics_frames(10)
	assert_gt(_player.stats.get_value(&"damage"), base)
	passive.free()
	assert_eq(_player.stats.get_value(&"damage"), base)


func test_arcane_echo_doubles_every_nth_attack() -> void:
	var staff := _player.weapons.add(STAFF)
	var passive := ArcaneEchoPassive.new()
	passive.every = 1
	_add_passive(passive)
	_add_dummy(Vector3(0.0, 0.0, -6.0))
	watch_signals(staff)
	await wait_physics_frames(30)
	assert_signal_emit_count(staff, "fired", 2, "un ataque de un orbe sale dos veces")


func test_lethal_adds_crit_per_level() -> void:
	var base := _player.stats.get_value(&"crit_chance")
	_player.set_character(ROGUE)
	var lethal := _player.passive as LethalPassive
	assert_not_null(lethal, "el Pícaro lleva Letal")
	var at_level_1 := _player.stats.get_value(&"crit_chance")
	assert_gt(at_level_1, base, "el Pícaro ya tiene más crítico")
	_player.experience.add(_player.experience.needed() + _player.experience.data.needed_for(2))
	assert_eq(_player.experience.get_level(), 3)
	assert_almost_eq(_player.stats.get_value(&"crit_chance"), at_level_1 + 2.0 * lethal.crit_per_level, 0.001)


func test_glide_caps_the_fall_while_holding_jump() -> void:
	_player.stats.add_modifier(StatModifier.create(&"glide_fall_speed", StatModifier.Kind.FLAT, 3.0), self)
	_player.position = Vector3(0.0, 50.0, 0.0)
	Input.action_press(InputActions.JUMP)
	await wait_physics_frames(60)
	assert_almost_eq(_player.velocity.y, -3.0, 0.05, "planea")
	Input.action_release(InputActions.JUMP)
	await wait_physics_frames(30)
	assert_lt(_player.velocity.y, -6.0, "suelta el salto y cae")


## Aguante como el del Guerrero (configurado antes de activarse).
func _endurance() -> EndurancePassive:
	var passive := EndurancePassive.new()
	passive.enemy_mask = PhysicsLayers.mask(PhysicsLayers.ENEMY_HURTBOX)
	passive.radius = 5.0
	passive.damage_per_enemy = 0.02
	passive.max_enemies = 15
	return passive


func _add_passive(passive: CharacterPassive) -> CharacterPassive:
	_player.add_child(passive)
	passive.activate(_player)
	return passive


func _add_dummy(at: Vector3) -> void:
	var dummy := DummyScene.instantiate() as Node3D
	dummy.position = at
	add_child_autofree(dummy)
