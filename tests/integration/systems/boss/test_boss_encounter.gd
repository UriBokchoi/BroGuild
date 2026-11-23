extends GutTest
## BossEncounter con física real y el jefe del Brosque: cuenta las llaves y lo avisa; el altar solo
## lo saca con las llaves (o al acabar la ronda, aunque falten), una vez por partida y más fuerte con
## la dificultad; pasa al HUD su vida y sus refuerzos salen por el director. Al vencerlo
## paran las oleadas, se retiran los demás, llega el premio (oro × rapidez y un objeto que el HUD
## revela y llega al acabar) y se avisa de la victoria.

const BOSS := preload("res://data/bosses/brosque.tres")
const WAVES := preload("res://data/waves/brosque.tres")
const SWARMER := preload("res://data/enemies/swarmer.tres")
const SAPLING := preload("res://data/enemies/sapling.tres")

var _swarm: EnemySwarm
var _director: WaveDirector
var _stats: StatsComponent
var _items: PassiveInventory
var _encounter: BossEncounter
var _keys: Array[Vector2i] = []
var _spawned: Array[StringName] = []
var _healths: Array[float] = []
var _revealed: Array[PassiveItemData] = []
var _gold: float = 0.0
var _victories: Array = []


func before_each() -> void:
	_keys.clear()
	_spawned.clear()
	_healths.clear()
	_revealed.clear()
	_victories.clear()
	_gold = 0.0
	_add_ground()
	await wait_physics_frames(1)
	var target := Node3D.new()
	add_child_autofree(target)
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)
	_stats = _player_stats()
	_director = WaveDirector.new()
	_director.data = WAVES
	_director.swarm = _swarm
	_director.target = target
	_director.difficulty_stats = _stats
	add_child_autofree(_director)
	_items = PassiveInventory.new()
	_items.stats = _stats
	add_child_autofree(_items)
	EventBus.boss_keys_changed.connect(_on_keys)
	EventBus.boss_spawned.connect(_on_spawned)
	EventBus.boss_health_changed.connect(_on_health)
	EventBus.item_revealed.connect(_on_revealed)
	EventBus.pickup_collected.connect(_on_pickup)
	EventBus.boss_defeated.connect(_on_defeated)
	_encounter = _make_encounter(BOSS)


func after_each() -> void:
	EventBus.boss_keys_changed.disconnect(_on_keys)
	EventBus.boss_spawned.disconnect(_on_spawned)
	EventBus.boss_health_changed.disconnect(_on_health)
	EventBus.item_revealed.disconnect(_on_revealed)
	EventBus.pickup_collected.disconnect(_on_pickup)
	EventBus.boss_defeated.disconnect(_on_defeated)


func test_counts_the_keys_and_says_how_many() -> void:
	assert_eq(_keys, [Vector2i(0, 3)] as Array[Vector2i], "al empezar, ninguna")
	EventBus.boss_key_collected.emit()
	EventBus.boss_key_collected.emit()
	var last: Vector2i = _keys.back()
	assert_eq(last, Vector2i(2, 3))
	assert_eq(_encounter.get_keys(), 2)


func test_the_altar_needs_the_keys() -> void:
	EventBus.boss_summon_requested.emit(Vector3(3.0, 0.0, 0.0), false)
	assert_false(_encounter.is_summoned(), "faltan llaves")
	for _key: int in BOSS.keys_needed:
		EventBus.boss_key_collected.emit()
	EventBus.boss_summon_requested.emit(Vector3(3.0, 0.0, 0.0), false)
	assert_true(_encounter.is_summoned())
	assert_eq(_spawned, [BOSS.enemy.name_key] as Array[StringName])
	var boss := _encounter.get_boss()
	assert_almost_eq(boss.global_position, Vector3(3.0, 0.0, 0.0), Vector3.ONE * 0.1, "sale donde dice el altar")


func test_at_the_end_of_the_round_it_comes_without_keys() -> void:
	EventBus.boss_summon_requested.emit(Vector3.ZERO, true)
	assert_true(_encounter.is_summoned())


func test_only_one_boss_per_run() -> void:
	assert_true(_encounter.summon(Vector3.ZERO))
	assert_false(_encounter.summon(Vector3(5.0, 0.0, 0.0)))
	assert_eq(_swarm.active_count(), 1)


func test_it_comes_stronger_with_the_difficulty() -> void:
	_stats.add_modifier(StatModifier.create(&"difficulty", StatModifier.Kind.FLAT, 10.0), self)
	_encounter.summon(Vector3.ZERO)
	var base := (BOSS.enemy.stat_sources[0] as HealthData).max_health
	var factor := BOSS.stat_scaling[0].multiplier_at(10.0)
	assert_almost_eq(_encounter.get_boss().health.get_maximum(), base * factor, 1.0)
	var shown: float = _healths.back()
	assert_almost_eq(shown, base * factor, 1.0, "el HUD sabe su vida")


func test_its_reinforcements_go_through() -> void:
	_encounter.summon(Vector3.ZERO)
	var boss := _encounter.get_boss()
	boss.summon(SAPLING, 3, 2.0, 4.0)
	assert_eq(_swarm.active_count(), 4, "el jefe y tres refuerzos")


func test_beating_it_wins_the_level_with_its_reward() -> void:
	_director.start()
	_encounter.summon(Vector3.ZERO)
	var boss := _encounter.get_boss()
	var minion := _swarm.spawn(SWARMER, Vector3(6.0, 0.0, 0.0))
	boss.health.take_damage(DamageInfo.create(boss.health.get_maximum() * 2.0))
	assert_false(_director.is_running(), "paran las oleadas")
	assert_false(minion.visible, "los demás se retiran")
	assert_eq(_swarm.get_active(), [boss] as Array[Enemy], "el jefe termina de caer")
	var bonus := BOSS.bonus_at(0.0)
	assert_almost_eq(_gold, BOSS.reward_gold * bonus, 1.0, "oro × lo pronto que cayó")
	assert_eq(_victories.size(), 1)
	var victory: Array = _victories[0]
	assert_eq(victory, [BOSS.victory_key, bonus])
	assert_eq(_revealed.size(), 1, "el HUD revela el objeto")
	assert_eq(_items.total(), 0, "aún revelándose")
	await wait_seconds(BOSS.reveal_time + 0.1)
	assert_eq(_items.get_items(), _revealed, "y le llega al acabar")


func test_without_a_boss_nothing_happens() -> void:
	var empty := _make_encounter(null)
	EventBus.boss_key_collected.emit()
	assert_eq(empty.get_keys(), 0)
	assert_false(empty.summon(Vector3.ZERO))


func _make_encounter(data: BossData) -> BossEncounter:
	var encounter := BossEncounter.new()
	encounter.data = data
	encounter.director = _director
	encounter.swarm = _swarm
	encounter.player_stats = _stats
	encounter.items = _items
	encounter.rng = RandomNumberGenerator.new()
	encounter.rng.seed = 4
	add_child_autofree(encounter)
	return encounter


## Todas las fuentes del jugador: cualquier objeto del premio tiene sus stats.
func _player_stats() -> StatsComponent:
	var stats := StatsComponent.new()
	for source: Resource in [OffenseData.new(), HealthData.new(), MovementData.new(), StaminaData.new(), ProgressionData.new(), MovementSynergyData.new()]:
		stats.sources.append(source)
	add_child_autofree(stats)
	return stats


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)


func _on_keys(keys: int, needed: int) -> void:
	_keys.append(Vector2i(keys, needed))


func _on_health(current: float, _maximum: float) -> void:
	_healths.append(current)


func _on_revealed(item: PassiveItemData, _reveal_time: float) -> void:
	_revealed.append(item)


func _on_pickup(reward: StringName, amount: float) -> void:
	if reward == &"gold":
		_gold += amount


func _on_defeated(victory_key: StringName, _seconds: float, bonus: float) -> void:
	_victories.append([victory_key, bonus])


func _on_spawned(name_key: StringName) -> void:
	_spawned.append(name_key)

