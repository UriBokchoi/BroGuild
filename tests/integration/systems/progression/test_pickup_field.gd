extends GutTest
## PickupField con física real: deja los recogibles en el suelo, vuelan hacia quien recoge al entrar
## en su radio (o nada más salir, el oro), al llegar avisan por el EventBus y vuelven al pool; los
## que esperan juntos se funden en uno de más nivel. El LootDropper suelta la gema de experiencia y
## la moneda de oro de cada enemigo que muere, y el botín de cada rompible en trozos alrededor (más
## cuanto mayor es la dificultad) y, con la probabilidad de botín (por el multiplicador de élites y
## rompibles), un extra de su tabla. Muchas muertes a la vez sueltan su botín repartido en unos
## pocos ticks, y los recogibles preparados de antemano esperan ocultos.

const XP_GEM := preload("res://data/pickups/xp_gem.tres")
const GOLD_COIN := preload("res://data/pickups/gold_coin.tres")
const SWARMER := preload("res://data/enemies/swarmer.tres")
const SKULL := preload("res://data/breakables/skull.tres")
const BOMB := preload("res://data/pickups/bomb.tres")
const ELITE := preload("res://data/enemies/elite.tres")

var _collector: Node3D
var _field: PickupField
var _dropper: LootDropper


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


func test_a_power_up_announces_itself_when_collected() -> void:
	_collector.position = Vector3(2.5, 0.0, 0.0)
	_field.drop(BOMB, Vector3.ZERO, 1.0)
	_field.drop(XP_GEM, Vector3(0.5, 0.0, 0.0), 1.0)
	watch_signals(EventBus)
	await wait_physics_frames(30)
	assert_eq(_field.active_count(), 0)
	assert_signal_emitted_with_parameters(EventBus, "announced", [BOMB.announce_key, [], BOMB.announce_color])
	assert_signal_emit_count(EventBus, "announced", 1, "la gema no dice nada")


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


func test_broken_breakables_drop_their_loot_in_pieces() -> void:
	var dropper := LootDropper.new()
	dropper.field = _field
	add_child_autofree(dropper)
	EventBus.breakable_broken.emit(SKULL, Vector3(-5.0, 0.0, 0.0))
	assert_eq(_field.active_count(), SKULL.pieces)
	var total := 0.0
	for pickup: Pickup in _field.get_active():
		assert_same(pickup.data, SKULL.reward)
		total += pickup.amount
		assert_lt(pickup.global_position.distance_to(Vector3(-5.0, pickup.global_position.y, 0.0)), SKULL.spread + 0.01)
	assert_almost_eq(total, SKULL.amount, 0.001)


func test_more_difficulty_more_loot_from_breakables() -> void:
	var stats := _player_stats(0.0)
	stats.add_modifier(StatModifier.create(&"difficulty", StatModifier.Kind.FLAT, 10.0), self)
	_make_dropper(stats)
	EventBus.breakable_broken.emit(SKULL, Vector3(-5.0, 0.0, 0.0))
	var total := 0.0
	for pickup: Pickup in _field.get_active():
		total += pickup.amount
	assert_almost_eq(total, SKULL.amount + SKULL.amount_per_difficulty * 10.0, 0.001)


func test_normal_enemies_drop_extras_with_the_drop_chance() -> void:
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	_make_dropper(_player_stats(0.0))
	swarm.spawn(SWARMER, Vector3(-8.0, 0.0, 0.0)).health.take_damage(DamageInfo.create(1000.0))
	assert_eq(_bombs(), 0, "con un 0 %, nada")
	_dropper.player_stats = _player_stats(100.0)
	swarm.spawn(SWARMER, Vector3(8.0, 0.0, 0.0)).health.take_damage(DamageInfo.create(1000.0))
	assert_eq(_bombs(), 1, "con un 100 %, de su tabla")


func test_elites_and_breakables_multiply_the_drop_chance() -> void:
	_make_dropper(_player_stats(10.0))
	var breakable := SKULL.duplicate() as BreakableData
	breakable.drop_table = _bomb_table()
	breakable.drop_chance_multiplier = 10.0
	EventBus.breakable_broken.emit(breakable, Vector3(-5.0, 0.0, 0.0))
	assert_eq(_bombs(), 1, "10 % × 10 del rompible")
	var elite := ELITE.duplicate() as EliteData
	elite.drop_table = _bomb_table()
	elite.drop_chance_multiplier = 10.0
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	var promoted := swarm.spawn(SWARMER, Vector3(8.0, 0.0, 0.0))
	promoted.promote(elite)
	promoted.health.take_damage(DamageInfo.create(100000.0))
	assert_eq(_bombs(), 2, "10 % × 10 del élite")


func test_elites_sometimes_drop_a_chest() -> void:
	_make_dropper(_player_stats(0.0))
	var chests := Node3D.new()
	add_child_autofree(chests)
	_dropper.chest_parent = chests
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	var elite := ELITE.duplicate() as EliteData
	elite.chest_chance = 0.0
	var unlucky := swarm.spawn(SWARMER, Vector3(-6.0, 0.0, 0.0))
	unlucky.promote(elite)
	unlucky.health.take_damage(DamageInfo.create(100000.0))
	assert_eq(chests.get_child_count(), 0, "con un 0 %, nada")
	elite.chest_chance = 100.0
	var lucky := swarm.spawn(SWARMER, Vector3(6.0, 0.0, 3.0))
	lucky.promote(elite)
	lucky.health.take_damage(DamageInfo.create(100000.0))
	assert_eq(chests.get_child_count(), 1, "con un 100 %, su cofre")
	var chest := chests.get_child(0) as Chest
	assert_not_null(chest, "un cofre normal")
	assert_almost_eq(chest.global_position.x, 6.0, 0.01, "donde cayó")
	swarm.spawn(SWARMER, Vector3(0.0, 0.0, 6.0)).health.take_damage(DamageInfo.create(1000.0))
	assert_eq(chests.get_child_count(), 1, "los normales no sueltan cofres")


func test_every_elite_can_drop_a_chest() -> void:
	assert_gt(ELITE.chest_chance, 0.0)
	assert_not_null(ELITE.chest)


func test_prewarmed_pickups_wait_out_of_the_world() -> void:
	_field.prewarm(XP_GEM, 5)
	assert_eq(_field.active_count(), 0)
	var waiting := _field.get_children().filter(func(child: Node) -> bool: return child is Pickup)
	assert_eq(waiting.size(), 5)
	for pickup: Pickup in waiting:
		assert_false(pickup.visible, "ocultos hasta que se suelten")
	var gem := _field.drop(XP_GEM, Vector3.ZERO, 1.0)
	assert_true(waiting.has(gem), "sale de los preparados")
	assert_true(gem.visible)


func test_a_mass_kill_drops_over_a_few_ticks() -> void:
	var dropper := LootDropper.new()
	dropper.field = _field
	dropper.xp_gem = XP_GEM
	dropper.max_drops_per_tick = 4
	add_child_autofree(dropper)
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	for index: int in 7:
		var enemy := swarm.spawn(SWARMER, Vector3(-5.0 - index * 2.0, 0.0, 0.0))
		enemy.health.take_damage(DamageInfo.create(1000.0))
	assert_eq(_field.active_count(), 4, "como mucho los de un tick")
	assert_eq(dropper.queued_count(), 3)
	await wait_physics_frames(2)
	assert_eq(_field.active_count(), 7, "el resto, en los siguientes")
	assert_eq(dropper.queued_count(), 0)


func _make_dropper(stats: StatsComponent) -> void:
	_dropper = LootDropper.new()
	_dropper.field = _field
	_dropper.player_stats = stats
	_dropper.enemy_drop_table = _bomb_table()
	add_child_autofree(_dropper)


func _player_stats(drop_chance: float) -> StatsComponent:
	var progression := ProgressionData.new()
	progression.drop_chance = drop_chance
	var stats := StatsComponent.new()
	stats.sources.append(progression)
	add_child_autofree(stats)
	return stats


## Tabla con un solo extra: una bomba.
func _bomb_table() -> WeightedTable:
	var bonus := BonusDrop.new()
	bonus.pickup = BOMB
	bonus.weight = 1.0
	bonus.amount = 1.0
	var table := WeightedTable.new()
	table.entries = [bonus] as Array[WeightedEntry]
	return table


func _bombs() -> int:
	return _field.get_active().filter(func(pickup: Pickup) -> bool: return pickup.data == BOMB).size()


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
