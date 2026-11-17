extends GutTest
## Mortal del doble salto: el Pícaro da la vuelta hacia delante al entrar en el doble salto y
## termina derecho; el Guerrero, no.

const PlayerScene := preload("res://entities/player/player.tscn")
const ROGUE := preload("res://data/characters/rogue.tres")
const WARRIOR := preload("res://data/characters/warrior.tres")


func before_each() -> void:
	RunState.character = null


func after_each() -> void:
	RunState.character = null


func test_the_rogue_flips_on_the_double_jump() -> void:
	var player := _make_player(ROGUE)
	var flip := player.get_node(^"BodyFlip") as BodyFlip
	flip.flip_time = 0.1
	player.movement.state_changed.emit(player.air_state, player.get_node(^"Movement/DoubleJump") as State)
	assert_true(flip.is_flipping())
	await wait_seconds(0.2)
	assert_false(flip.is_flipping())
	assert_eq(player.model.rotation.x, 0.0, "termina derecho")


func test_the_warrior_does_not_flip() -> void:
	var player := _make_player(WARRIOR)
	var flip := player.get_node(^"BodyFlip") as BodyFlip
	player.movement.state_changed.emit(player.air_state, player.get_node(^"Movement/DoubleJump") as State)
	assert_false(flip.is_flipping())


func _make_player(character: CharacterData) -> Player:
	var player := PlayerScene.instantiate() as Player
	player.character = character
	add_child_autofree(player)
	return player
