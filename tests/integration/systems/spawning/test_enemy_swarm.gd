extends GutTest
## EnemySwarm con física real y el esbirro: saca enemigos del pool, los lleva hacia el objetivo
## chocando entre sí (pueden quedar apilados), los guarda al morir para reutilizarlos (mientras
## mueren ya no chocan con nadie) y retira a los que caen del mapa.

const SWARMER := preload("res://data/enemies/swarmer.tres")
const ELITE := preload("res://data/enemies/elite.tres")

var _swarm: EnemySwarm
var _target: Node3D


func before_each() -> void:
	_add_ground()
	_target = Node3D.new()
	add_child_autofree(_target)
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)


func test_spawns_an_enemy_with_full_health() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3(2.0, 0.0, 0.0))
	assert_eq(_swarm.active_count(), 1)
	assert_true(enemy.is_alive())
	assert_eq(enemy.global_position, Vector3(2.0, 0.0, 0.0))
	assert_eq(enemy.health.get_current(), enemy.health.get_maximum())


func test_chases_the_target() -> void:
	_swarm.target = _target
	_target.position = Vector3(0.0, 0.0, 0.0)
	var enemy := _swarm.spawn(SWARMER, Vector3(8.0, 0.0, 0.0))
	await wait_physics_frames(30)
	var flat := Vector2(enemy.global_position.x, enemy.global_position.z)
	assert_lt(flat.length(), 7.0, "se acerca (con su desvío)")


func test_enemies_spread_instead_of_stacking() -> void:
	var first := _swarm.spawn(SWARMER, Vector3.ZERO)
	var second := _swarm.spawn(SWARMER, Vector3.ZERO)
	await wait_physics_frames(30)
	assert_gt(first.global_position.distance_to(second.global_position), 0.5)


func test_an_enemy_can_stand_on_top_of_another() -> void:
	var below := _swarm.spawn(SWARMER, Vector3.ZERO)
	var above := _swarm.spawn(SWARMER, Vector3(0.0, 2.0, 0.0))
	await wait_physics_frames(40)
	assert_gt(above.global_position.y, below.global_position.y + 1.0, "apilado encima")


func test_a_crowd_piles_up_around_the_target_without_flying_off() -> void:
	_swarm.target = _target
	for index: int in 24:
		var angle := TAU * index / 24.0
		_swarm.spawn(SWARMER, Vector3(cos(angle), 0.0, sin(angle)) * 6.0)
	await wait_physics_frames(150)
	var highest := 0.0
	for enemy: Enemy in _swarm.get_active():
		highest = maxf(highest, enemy.global_position.y)
	assert_gt(highest, 1.0, "se suben unos encima de otros")
	assert_lt(highest, 10.0, "no hacen torres hasta el cielo")


func test_dead_enemies_vanish_and_are_reused_full() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	watch_signals(EventBus)
	enemy.health.take_damage(DamageInfo.create(1000.0))
	assert_signal_emitted_with_parameters(EventBus, "enemy_died", [enemy])
	await wait_physics_frames(20)
	assert_eq(_swarm.active_count(), 0, "terminó de morir")
	assert_false(enemy.visible)
	var again := _swarm.spawn(SWARMER, Vector3.ZERO)
	assert_same(again, enemy, "sale del pool")
	assert_true(again.is_alive())
	assert_eq(again.health.get_current(), again.health.get_maximum())


func test_enemies_that_fall_off_are_retired() -> void:
	_swarm.spawn(SWARMER, Vector3(0.0, _swarm.kill_height - 10.0, 0.0))
	await wait_physics_frames(2)
	assert_eq(_swarm.active_count(), 0)


func test_a_dying_enemy_no_longer_blocks_anyone() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	var layer := enemy.collision_layer
	var mask := enemy.collision_mask
	enemy.health.take_damage(DamageInfo.create(enemy.health.get_maximum() * 10.0))
	assert_eq(enemy.collision_layer, 0, "ni el jugador ni los demás chocan con él")
	assert_eq(enemy.collision_mask, PhysicsLayers.mask(PhysicsLayers.WORLD), "solo se apoya en el suelo")
	await wait_seconds(enemy.death_time + 0.1)
	var again := _swarm.spawn(SWARMER, Vector3.ZERO)
	assert_same(again, enemy, "el mismo, del pool")
	assert_eq(again.collision_layer, layer, "vivo, vuelve a chocar")
	assert_eq(again.collision_mask, mask)


func test_clear_retires_everyone() -> void:
	for index: int in 3:
		_swarm.spawn(SWARMER, Vector3(index * 2.0, 0.0, 0.0))
	_swarm.clear()
	assert_eq(_swarm.active_count(), 0)


func test_clear_can_let_the_dying_finish() -> void:
	var dying := _swarm.spawn(SWARMER, Vector3(0.0, 0.0, 0.0))
	var alive := _swarm.spawn(SWARMER, Vector3(3.0, 0.0, 0.0))
	dying.health.take_damage(DamageInfo.create(dying.health.get_maximum() * 10.0))
	_swarm.clear(true)
	assert_eq(_swarm.get_active(), [dying] as Array[Enemy], "el que muere termina de encoger (el jefe vencido)")
	assert_false(alive.visible)


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


func test_hits_push_enemies_and_heavy_ones_less() -> void:
	var light := _swarm.spawn(SWARMER, Vector3(0.0, 0.0, 0.0))
	var heavy := _swarm.spawn(SWARMER, Vector3(0.0, 0.0, 6.0))
	heavy.promote(ELITE)
	await wait_physics_frames(2)
	for enemy: Enemy in [light, heavy]:
		enemy.hurtbox.receive(DamageInfo.create(1.0, false, null, Vector3(8.0, 0.0, 0.0)))
	await wait_physics_frames(1)
	assert_gt(light.linear_velocity.x, 3.0, "lo empuja")
	assert_lt(heavy.linear_velocity.x, light.linear_velocity.x, "al élite, más pesado, menos")
