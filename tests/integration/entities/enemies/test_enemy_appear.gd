extends GutTest
## Aparición de los enemigos: al salir del pool, el modelo sale del suelo creciendo y avisa
## (enemy_spawned); al terminar queda a su tamaño y en su sitio, también si era élite. Si muere
## mientras sale, deja de aparecer y encoge como siempre.

const SWARMER := preload("res://data/enemies/swarmer.tres")
const ELITE := preload("res://data/enemies/elite.tres")

var _swarm: EnemySwarm
var _spawned: Array[Enemy] = []


func before_each() -> void:
	_spawned.clear()
	EventBus.enemy_spawned.connect(_on_spawned)
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)


func after_each() -> void:
	EventBus.enemy_spawned.disconnect(_on_spawned)


func test_it_rises_from_the_ground_and_ends_as_usual() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3(1.0, 0.0, 2.0))
	assert_eq(_spawned, [enemy] as Array[Enemy], "avisa")
	assert_true(enemy.is_appearing())
	var rest_y := enemy.visual.position.y + enemy.appear_depth
	assert_lt(enemy.visual.scale.x, 0.1, "empieza pequeño")
	await wait_seconds(enemy.appear_time * 0.5)
	assert_gt(enemy.visual.scale.x, 0.1, "crece")
	await wait_seconds(enemy.appear_time * 0.5 + 0.05)
	assert_false(enemy.is_appearing())
	assert_almost_eq(enemy.visual.position.y, rest_y, 1e-4, "en su sitio")
	var fresh := _swarm.spawn(SWARMER, Vector3(-4.0, 0.0, 0.0))
	await wait_seconds(enemy.appear_time + 0.05)
	assert_eq(enemy.visual.scale, fresh.visual.scale, "a su tamaño")


func test_an_elite_ends_at_its_size() -> void:
	var normal := _swarm.spawn(SWARMER, Vector3(-4.0, 0.0, 0.0))
	var elite := _swarm.spawn(SWARMER, Vector3(4.0, 0.0, 0.0))
	elite.promote(ELITE)
	await wait_seconds(elite.appear_time + 0.05)
	assert_almost_eq(elite.visual.scale.x, normal.visual.scale.x * ELITE.size, 1e-4)


func test_dying_while_appearing_stops_it() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	await wait_process_frames(2)
	enemy.health.take_damage(DamageInfo.create(1.0e6))
	await wait_process_frames(2)
	assert_false(enemy.is_appearing())
	var shrinking := enemy.visual.scale.x
	await wait_physics_frames(2)
	assert_lt(enemy.visual.scale.x, shrinking + 1e-4, "encoge, no vuelve a crecer")


func _on_spawned(enemy: Enemy) -> void:
	_spawned.append(enemy)
