extends GutTest
## PickupField con física real: deja los recogibles en el suelo, vuelan hacia quien recoge al entrar
## en su radio (o nada más salir, el oro), al llegar avisan por el EventBus y vuelven al pool; los
## que esperan juntos se funden en uno de más nivel. El LootDropper suelta la gema de experiencia y
## la moneda de oro de cada enemigo que muere.

const XP_GEM := preload("res://data/pickups/xp_gem.tres")
const GOLD_COIN := preload("res://data/pickups/gold_coin.tres")
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


func test_gold_flies_to_the_collector_from_anywhere() -> void:
	var coin := _field.drop(GOLD_COIN, Vector3.ZERO, 2.0)
	assert_true(coin.attracted, "vuela nada más salir")
	watch_signals(EventBus)
	await wait_physics_frames(60)
	assert_eq(_field.active_count(), 0, "recogida a 20 m")
	assert_signal_emitted_with_parameters(EventBus, "pickup_collected", [&"gold", 2.0])


func test_gems_close_together_merge_into_one_of_a_higher_tier() -> void:
	for index: int in XP_GEM.merge_count:
		_field.drop(XP_GEM, Vector3(index * 0.3, 0.0, 0.5), 1.0)
	_field.merge_nearby()
	assert_eq(_field.active_count(), 1)
	var gem := _field.get_active()[0]
	assert_eq(gem.amount, float(XP_GEM.merge_count), "con el valor sumado")
	assert_eq(gem.visual.scale, Vector3.ONE * XP_GEM.tier_for(gem.amount).scale)
	assert_gt(gem.visual.scale.x, XP_GEM.tier_for(1.0).scale, "de otro nivel")


func test_too_few_or_far_apart_gems_do_not_merge() -> void:
	for index: int in XP_GEM.merge_count - 1:
		_field.drop(XP_GEM, Vector3(index * 0.3, 0.0, 0.5), 1.0)
	_field.drop(XP_GEM, Vector3(-10.0, 0.0, 0.5), 1.0)
	_field.merge_nearby()
	assert_eq(_field.active_count(), XP_GEM.merge_count)


func test_flying_gems_do_not_merge() -> void:
	for index: int in XP_GEM.merge_count:
		_field.drop(XP_GEM, Vector3(index * 0.3, 0.0, 0.5), 1.0).attracted = true
	_field.merge_nearby()
	assert_eq(_field.active_count(), XP_GEM.merge_count)


func test_merges_on_its_own_every_interval() -> void:
	for index: int in XP_GEM.merge_count:
		_field.drop(XP_GEM, Vector3(index * 0.3, 0.0, 0.5), 1.0)
	await wait_seconds(_field.merge_interval + 0.1)
	assert_eq(_field.active_count(), 1)


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


func test_dead_enemies_also_drop_their_gold() -> void:
	var dropper := LootDropper.new()
	dropper.field = _field
	dropper.xp_gem = XP_GEM
	dropper.gold_coin = GOLD_COIN
	add_child_autofree(dropper)
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	var enemy := swarm.spawn(SWARMER, Vector3(-5.0, 0.0, 0.0))
	enemy.health.take_damage(DamageInfo.create(1000.0))
	var coins := _field.get_active().filter(func(pickup: Pickup) -> bool: return pickup.data == GOLD_COIN)
	assert_eq(coins.size(), 1)
	assert_gt(enemy.gold_reward(), 0.0)
	assert_eq((coins[0] as Pickup).amount, enemy.gold_reward())


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
