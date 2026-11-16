extends GutTest
## Tirador contra el jugador, con física real: lleva las armas de sus datos, se queda a su distancia
## (se acerca desde lejos y se aleja si está cerca), no dispara nada más salir, sus disparos dañan al
## jugador, atraviesan a otros enemigos, las paredes los paran, siguen volando si muere y hay un
## máximo en vuelo a la vez.

const PlayerScene := preload("res://entities/player/player.tscn")
const SHOOTER := preload("res://data/enemies/shooter.tres")
const DummyScene := preload("res://entities/enemies/target_dummy/target_dummy.tscn")

var _player: Player
var _swarm: EnemySwarm


func before_each() -> void:
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(80.0, 1.0, 80.0))
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_swarm = EnemySwarm.new()
	_swarm.target = _player
	add_child_autofree(_swarm)


func test_carries_the_weapons_of_its_data() -> void:
	var enemy := _swarm.spawn(SHOOTER, Vector3(12.0, 0.0, 0.0))
	assert_not_null(enemy.weapons)
	assert_eq(enemy.weapons.get_weapons().size(), SHOOTER.weapons.size())


func test_closes_in_from_far_and_keeps_its_distance() -> void:
	var enemy := _swarm.spawn(SHOOTER, Vector3(_keep() + 5.0, 0.0, 0.0))
	await wait_physics_frames(200)
	assert_between(_flat_distance(enemy), _keep() - 1.5, _keep() + 1.5)


func test_backs_off_when_too_close() -> void:
	var enemy := _swarm.spawn(SHOOTER, Vector3(4.0, 0.0, 0.0))
	await wait_physics_frames(75)
	assert_gt(_flat_distance(enemy), 6.0)


func test_does_not_shoot_as_soon_as_it_appears() -> void:
	var enemy := _swarm.spawn(SHOOTER, Vector3(_keep(), 0.0, 0.0))
	var weapon := enemy.weapons.get_weapons()[0]
	watch_signals(weapon)
	await wait_physics_frames(20)
	assert_signal_not_emitted(weapon, "fired", "espera parte de su espera normal")


func test_its_shots_hurt_the_player() -> void:
	var enemy := _swarm.spawn(SHOOTER, Vector3(_keep(), 0.0, 0.0))
	_fire_now(enemy)
	await wait_physics_frames(90)
	assert_lt(_player.health.get_current(), _player.health.get_maximum())


func test_walls_stop_its_shots() -> void:
	_add_box(Vector3(5.0, 1.5, 0.0), Vector3(0.5, 3.0, 8.0))
	var enemy := _swarm.spawn(SHOOTER, Vector3(_keep(), 0.0, 0.0))
	_fire_now(enemy)
	await wait_physics_frames(90)
	assert_eq(_player.health.get_current(), _player.health.get_maximum())


func test_its_shots_keep_flying_after_it_dies() -> void:
	var enemy := _swarm.spawn(SHOOTER, Vector3(_keep(), 0.0, 0.0))
	var weapon := enemy.weapons.get_weapons()[0]
	watch_signals(weapon)
	_fire_now(enemy)
	await wait_physics_frames(10)
	assert_signal_emitted(weapon, "fired")
	enemy.health.take_damage(DamageInfo.create(1000.0))
	await wait_physics_frames(90)
	assert_lt(_player.health.get_current(), _player.health.get_maximum(), "su disparo llega igual")
	assert_signal_emit_count(weapon, "fired", 1, "y no dispara más")


func test_shots_go_through_other_enemies() -> void:
	var enemy := _swarm.spawn(SHOOTER, Vector3(_keep(), 0.0, 0.0))
	var blocker := DummyScene.instantiate() as Node3D
	blocker.position = Vector3(4.0, 0.0, 0.0)
	add_child_autofree(blocker)
	_fire_now(enemy)
	await wait_physics_frames(90)
	assert_lt(_player.health.get_current(), _player.health.get_maximum())


func test_there_is_a_limit_of_shots_in_flight() -> void:
	_swarm.projectiles.limit = 2
	for index: int in 5:
		var enemy := _swarm.spawn(SHOOTER, Vector3(_keep(), 0.0, -4.0 + index * 2.0))
		_fire_now(enemy)
	await wait_physics_frames(5)
	assert_eq(_swarm.projectiles.flying_count(), 2)


func _keep() -> float:
	for source: Resource in SHOOTER.stat_sources:
		var stats := source as EnemyStats
		if stats:
			return stats.keep_distance
	return 0.0


func _fire_now(enemy: Enemy) -> void:
	for weapon: Weapon in enemy.weapons.get_weapons():
		weapon.rearm(0.0)


func _flat_distance(enemy: Enemy) -> float:
	var offset := enemy.global_position - _player.global_position
	return Vector2(offset.x, offset.z).length()


func _add_box(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	body.position = at
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
