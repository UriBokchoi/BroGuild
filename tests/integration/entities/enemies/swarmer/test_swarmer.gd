extends GutTest
## Esbirro contra el jugador, con física real: lo persigue y le hace daño al tocarlo; las armas
## del jugador lo matan. Capas de enemigo.

const PlayerScene := preload("res://entities/player/player.tscn")
const SWARMER := preload("res://data/enemies/swarmer.tres")
const SWORD := preload("res://data/weapons/sword.tres")

var _player: Player
var _swarm: EnemySwarm


func before_each() -> void:
	_add_ground()
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_swarm = EnemySwarm.new()
	_swarm.target = _player
	add_child_autofree(_swarm)


func test_uses_the_enemy_layers() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3(5.0, 0.0, 0.0))
	assert_eq(enemy.collision_layer, PhysicsLayers.mask(PhysicsLayers.ENEMY))
	assert_eq(enemy.collision_mask, PhysicsLayers.mask(PhysicsLayers.WORLD))
	assert_eq(enemy.hurtbox.collision_layer, PhysicsLayers.mask(PhysicsLayers.ENEMY_HURTBOX))
	assert_eq(enemy.contact_hitbox.collision_layer, PhysicsLayers.mask(PhysicsLayers.ENEMY_HITBOX))
	assert_eq(enemy.contact_hitbox.collision_mask, PhysicsLayers.mask(PhysicsLayers.PLAYER_HURTBOX))


func test_touching_the_player_hurts_it() -> void:
	_swarm.spawn(SWARMER, Vector3(2.0, 0.0, 0.0))
	await wait_physics_frames(40)
	assert_lt(_player.health.get_current(), _player.health.get_maximum())


func test_the_sword_kills_it() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3(0.0, 0.0, -2.0))
	_player.weapons.add(SWORD).set_level(SWORD.max_level())
	watch_signals(enemy)
	await wait_physics_frames(30)
	assert_signal_emitted(enemy, "died")


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)
