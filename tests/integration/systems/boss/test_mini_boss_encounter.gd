extends GutTest
## MiniBossEncounter con física real y el Trolleador Cara: con las oleadas en marcha, avisa con su
## texto unos segundos antes de su minuto y lo saca cerca del jugador, más fuerte con la dificultad;
## pasa al HUD su vida y sus gritos y, al vencerlo, avisa y da el premio (oro y un objeto que el HUD
## revela y llega al acabar). Con las oleadas paradas no corre el tiempo. En el Brosque sale a los
## 4:30, entre las dos hordas.

const BROSQUE_WAVES := preload("res://data/waves/brosque.tres")
const TROLLEADOR := preload("res://data/enemies/trolleador.tres")
const SECONDS := 1.0
const WARNING := 0.6

var _director: WaveDirector
var _encounter: MiniBossEncounter
var _items: PassiveInventory
var _target: Node3D
var _announced: Array[StringName] = []
var _spawned: Array[StringName] = []
var _healths: Array[float] = []
var _defeated: Array[StringName] = []
var _revealed: Array[PassiveItemData] = []
var _gold: float = 0.0


func before_each() -> void:
	_announced.clear()
	_spawned.clear()
	_healths.clear()
	_defeated.clear()
	_revealed.clear()
	_gold = 0.0
	_add_ground()
	await wait_physics_frames(1)
	_target = Node3D.new()
	add_child_autofree(_target)
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	# Todas las fuentes del jugador: el objeto del premio puede tocar cualquiera de sus stats.
	var stats := StatsComponent.new()
	for source: Resource in [OffenseData.new(), HealthData.new(), MovementData.new(), StaminaData.new(), ProgressionData.new(), MovementSynergyData.new()]:
		stats.sources.append(source)
	add_child_autofree(stats)
	_director = WaveDirector.new()
	_director.data = _waves()
	_director.swarm = swarm
	_director.target = _target
	_director.difficulty_stats = stats
	add_child_autofree(_director)
	_items = PassiveInventory.new()
	_items.stats = stats
	add_child_autofree(_items)
	_encounter = MiniBossEncounter.new()
	_encounter.director = _director
	_encounter.player_stats = stats
	_encounter.items = _items
	add_child_autofree(_encounter)
	EventBus.announced.connect(_on_announced)
	EventBus.mini_boss_spawned.connect(_on_spawned)
	EventBus.mini_boss_health_changed.connect(_on_health)
	EventBus.mini_boss_defeated.connect(_on_defeated)
	EventBus.item_revealed.connect(_on_revealed)
	EventBus.pickup_collected.connect(_on_pickup)


func after_each() -> void:
	EventBus.announced.disconnect(_on_announced)
	EventBus.mini_boss_spawned.disconnect(_on_spawned)
	EventBus.mini_boss_health_changed.disconnect(_on_health)
	EventBus.mini_boss_defeated.disconnect(_on_defeated)
	EventBus.item_revealed.disconnect(_on_revealed)
	EventBus.pickup_collected.disconnect(_on_pickup)


func test_the_brosque_troll_comes_between_the_two_hordes() -> void:
	var troll := BROSQUE_WAVES.mini_bosses[0]
	assert_eq(troll.enemy, TROLLEADOR)
	assert_gt(troll.at_minute, BROSQUE_WAVES.hordes[0].at_minute)
	assert_lt(troll.at_minute, BROSQUE_WAVES.hordes[1].at_minute)
	assert_not_null(troll.reward_items, "da un objeto")


func test_it_warns_then_comes_near_the_player() -> void:
	_director.start()
	await wait_seconds(SECONDS - WARNING + 0.1)
	assert_has(_announced, &"TROLLEADOR_INCOMING", "avisa antes")
	assert_true(_spawned.is_empty(), "aún no ha salido")
	await wait_seconds(WARNING + 0.1)
	assert_eq(_spawned, [&"ENEMY_TROLLEADOR_NAME"] as Array[StringName])
	assert_eq(_encounter.alive().size(), 1)
	var troll := _encounter.alive()[0]
	var data := _director.data.mini_bosses[0]
	var distance := Vector2(troll.global_position.x, troll.global_position.z).length()
	assert_between(distance, data.min_distance - 0.1, data.max_distance + 0.1)
	assert_false(_healths.is_empty(), "el HUD sabe su vida")


func test_it_comes_stronger_with_the_difficulty() -> void:
	var data := _director.data.mini_bosses[0]
	var weak := _encounter.summon(data)
	var base := weak.health.get_maximum()
	_director.difficulty_stats.add_modifier(StatModifier.create(&"difficulty", StatModifier.Kind.FLAT, 10.0), self)
	var strong := _encounter.summon(data)
	assert_gt(strong.health.get_maximum(), base * 2.0)


func test_beating_it_gives_its_reward() -> void:
	var data := _director.data.mini_bosses[0]
	var troll := _encounter.summon(data)
	troll.health.take_damage(DamageInfo.create(1.0e6))
	assert_eq(_defeated, [&"ENEMY_TROLLEADOR_NAME"] as Array[StringName])
	assert_almost_eq(_gold, data.reward_gold, 0.01)
	assert_eq(_revealed.size(), 1, "revela un objeto")
	assert_true(_encounter.alive().is_empty())
	await get_tree().create_timer(data.reveal_time + 0.1, true).timeout
	assert_eq(_items.count(_revealed[0]), 1, "llega al acabar de revelarse")


func test_with_the_waves_stopped_time_does_not_run() -> void:
	await wait_seconds(SECONDS + 0.2)
	assert_true(_spawned.is_empty())
	assert_true(_announced.is_empty())


## Las oleadas del Brosque sin enemigos ni hordas y con el troll al segundo [constant SECONDS].
func _waves() -> WaveData:
	var waves := BROSQUE_WAVES.duplicate() as WaveData
	waves.enemies = []
	waves.hordes = []
	var troll := BROSQUE_WAVES.mini_bosses[0].duplicate() as MiniBossData
	troll.at_minute = SECONDS / 60.0
	troll.warning_seconds = WARNING
	waves.mini_bosses = [troll]
	return waves


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(120.0, 1.0, 120.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)


func _on_announced(text_key: StringName, _args: Array, _color: Color) -> void:
	_announced.append(text_key)


func _on_spawned(name_key: StringName) -> void:
	_spawned.append(name_key)


func _on_health(current: float, _maximum: float) -> void:
	_healths.append(current)


func _on_defeated(name_key: StringName) -> void:
	_defeated.append(name_key)


func _on_revealed(item: PassiveItemData, _reveal_time: float) -> void:
	_revealed.append(item)


func _on_pickup(reward: StringName, amount: float) -> void:
	if reward == &"gold":
		_gold += amount
