extends GutTest
## PickupField con física real: deja los recogibles en el suelo, vuelan hacia quien recoge al entrar
## en su radio, al llegar avisan por el EventBus y vuelven al pool. El LootDropper suelta la gema de
## experiencia de cada enemigo que muere.

const XP_GEM := preload("res://data/pickups/xp_gem.tres")
const SWARMER := preload("res://data/enemies/swarmer.tres")

var _collector: Node3D
var _field: PickupField


func before_each() -> void:
	_add_ground()
	var progression := ProgressionData.new()
	progression.xp_gain = 100.0
	progression.pickup_range = 3.0
	var stats := StatsComponent.new()
	stats.sources.append(progression)
	add_child_autofree(stats)
	_collector = Node3D.new()
	_collector.position = Vector3(20.0, 0.0, 0.0)
	add_child_autofree(_collector)
	_field = PickupField.new()
	_field.collector = _collector
	_field.collector_stats = stats
	add_child_autofree(_field)


func test_drops_on_the_ground() -> void:
	await wait_physics_frames(2)
	var gem := _field.drop(XP_GEM, Vector3(0.0, 5.0, 0.0), 1.0)
	assert_almost_eq(gem.global_position.y, gem.float_height, 0.05, "flota sobre el suelo")


func test_stays_while_the_collector_is_far() -> void:
	var gem := _field.drop(XP_GEM, Vector3.ZERO, 1.0)
	var start := gem.global_position
	await wait_physics_frames(10)
	assert_eq(gem.global_position, start)
	assert_false(gem.attracted)


func test_flies_to_the_collector_in_range_and_is_collected() -> void:
	_collector.position = Vector3(2.5, 0.0, 0.0)
	_field.drop(XP_GEM, Vector3.ZERO, 3.0)
	watch_signals(EventBus)
	await wait_physics_frames(30)
	assert_eq(_field.active_count(), 0, "recogida")
	assert_signal_emitted_with_parameters(EventBus, "pickup_collected", [&"experience", 3.0])


func test_collected_gems_are_reused() -> void:
	_collector.position = Vector3(1.0, 0.0, 0.0)
	var first := _field.drop(XP_GEM, Vector3.ZERO, 1.0)
	await wait_physics_frames(20)
	assert_same(_field.drop(XP_GEM, Vector3.ZERO, 1.0), first)


func test_dead_enemies_drop_their_experience() -> void:
	var dropper := LootDropper.new()
	dropper.field = _field
	dropper.xp_gem = XP_GEM
	add_child_autofree(dropper)
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	var enemy := swarm.spawn(SWARMER, Vector3(-5.0, 0.0, 0.0))
	enemy.health.take_damage(DamageInfo.create(1000.0))
	assert_eq(_field.active_count(), 1)
	assert_eq(_field.get_active()[0].amount, enemy.xp_reward())


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)
