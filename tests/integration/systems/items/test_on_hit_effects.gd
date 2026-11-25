extends GutTest
## Efectos al golpear con enemigos de verdad: el veneno quita una parte del golpe a cada tick y se
## acaba; el rayo salta a los cercanos y no a los lejanos; el frío frena y se pasa; las copias suman
## probabilidad; el daño de un efecto no dispara más efectos; y sin el objeto no pasa nada.

const SWARMER := preload("res://data/enemies/swarmer.tres")

var _swarm: EnemySwarm
var _items: PassiveInventory
var _effects: OnHitEffects
var _hits: Array[DamageInfo] = []


func before_each() -> void:
	_hits.clear()
	EventBus.enemy_hit.connect(_on_hit)
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)
	var stats := StatsComponent.new()
	stats.sources.append(OffenseData.new())
	add_child_autofree(stats)
	_items = PassiveInventory.new()
	_items.stats = stats
	add_child_autofree(_items)
	_effects = OnHitEffects.new()
	_effects.items = _items
	_effects.chain_mask = PhysicsLayers.mask(PhysicsLayers.ENEMY_HURTBOX)
	add_child_autofree(_effects)


func after_each() -> void:
	EventBus.enemy_hit.disconnect(_on_hit)


func test_poison_takes_a_share_of_the_hit_each_tick() -> void:
	var poison := PoisonOnHit.new()
	poison.chance = 100.0
	poison.tick_share = 0.1
	poison.tick_interval = 0.2
	poison.duration = 0.6
	poison.kind = &"poison"
	_items.add(_item(&"poison", poison))
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	enemy.hurtbox.receive(DamageInfo.create(10.0))
	var after_hit := enemy.health.get_current()
	assert_true(_effects.is_poisoned(enemy.health))
	await wait_seconds(0.75)
	assert_almost_eq(enemy.health.get_current(), after_hit - 3.0, 0.01, "tres ticks de 1 (el 10 % de 10)")
	assert_false(_effects.is_poisoned(enemy.health), "y se acaba")
	var from_effects := _hits.filter(func(info: DamageInfo) -> bool: return not info.triggers_effects)
	assert_eq(from_effects.size(), 3)
	assert_eq((from_effects[0] as DamageInfo).kind, &"poison", "sus números, de su color")


func test_lightning_jumps_to_the_near_ones() -> void:
	var chain := ChainOnHit.new()
	chain.chance = 100.0
	chain.jumps = 2
	chain.reach = 6.0
	chain.damage_share = 0.5
	_items.add(_item(&"chain", chain))
	var first := _swarm.spawn(SWARMER, Vector3.ZERO)
	var near := _swarm.spawn(SWARMER, Vector3(3.0, 0.0, 0.0))
	var far := _swarm.spawn(SWARMER, Vector3(25.0, 0.0, 0.0))
	await wait_physics_frames(3)
	var full := near.health.get_maximum()
	first.hurtbox.receive(DamageInfo.create(8.0))
	assert_almost_eq(near.health.get_current(), full - 4.0, 0.01, "la mitad del golpe")
	assert_eq(far.health.get_current(), far.health.get_maximum(), "demasiado lejos")


func test_cold_slows_and_wears_off() -> void:
	var cold := SlowOnHit.new()
	cold.chance = 100.0
	cold.speed_factor = 0.5
	cold.duration = 0.3
	_items.add(_item(&"cold", cold))
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	var speed := enemy.stats.get_value(&"move_speed")
	enemy.hurtbox.receive(DamageInfo.create(1.0))
	assert_almost_eq(enemy.stats.get_value(&"move_speed"), speed * 0.5, 0.001)
	assert_true(_effects.is_slowed(enemy))
	await wait_seconds(0.45)
	assert_almost_eq(enemy.stats.get_value(&"move_speed"), speed, 0.001, "se le pasa")


func test_copies_add_up_their_chance() -> void:
	var poison: OnHitEffect = PoisonOnHit.new()
	poison.chance = 30.0
	var item := _item(&"copies", poison)
	_items.add(item)
	_items.add(item)
	assert_eq(_items.on_hit_effects()[poison], 2)


func test_without_the_item_nothing_happens() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	enemy.hurtbox.receive(DamageInfo.create(1.0))
	assert_false(_effects.is_poisoned(enemy.health))
	assert_false(_effects.is_slowed(enemy))


func _item(id: StringName, effect: OnHitEffect) -> PassiveItemData:
	var item := PassiveItemData.new()
	item.id = id
	item.on_hit.append(effect)
	return item


func _on_hit(_target: Node3D, _health: HealthComponent, info: DamageInfo, _amount: float) -> void:
	_hits.append(info)
