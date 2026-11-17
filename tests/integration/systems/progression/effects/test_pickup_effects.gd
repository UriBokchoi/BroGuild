extends GutTest
## Efectos de los recogibles especiales: la comida cura una parte de la vida máxima, el imán atrae
## toda la experiencia del mapa y la bomba quita su parte de vida a los enemigos cercanos (no a los
## lejanos), la bebida energética mejora stats un rato (otra lata no lo acumula), la mejora gratis
## sube lo que se lleva sin pasar del máximo y la oleada de élites los saca. Solo reaccionan a
## su recompensa.

const PlayerScene := preload("res://entities/player/player.tscn")
const XP_GEM := preload("res://data/pickups/xp_gem.tres")
const SWARMER := preload("res://data/enemies/swarmer.tres")
const ENERGY_BUFF := preload("res://data/pickups/energy_drink_buff.tres")


func before_each() -> void:
	RunState.character = null


func test_food_heals_part_of_the_max_health() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var heal := HealEffect.new()
	heal.reward = &"heal"
	heal.health = player.health
	add_child_autofree(heal)
	var maximum := player.health.get_maximum()
	player.health.take_damage(DamageInfo.create(maximum * 0.5))
	var hurt := player.health.get_current()
	EventBus.pickup_collected.emit(&"experience", 0.25)
	assert_eq(player.health.get_current(), hurt, "otra recompensa no cura")
	EventBus.pickup_collected.emit(&"heal", 0.25)
	assert_almost_eq(player.health.get_current(), hurt + maximum * 0.25, 0.01)


func test_the_magnet_attracts_all_the_experience() -> void:
	var collector := Node3D.new()
	add_child_autofree(collector)
	var stats := StatsComponent.new()
	var progression := ProgressionData.new()
	progression.pickup_range = 1.0
	stats.sources.append(progression)
	add_child_autofree(stats)
	var field := PickupField.new()
	field.collector = collector
	field.collector_stats = stats
	add_child_autofree(field)
	var near := field.drop(XP_GEM, Vector3(20.0, 0.0, 0.0), 1.0)
	var far := field.drop(XP_GEM, Vector3(-40.0, 0.0, 30.0), 1.0)
	var magnet := MagnetEffect.new()
	magnet.reward = &"magnet"
	magnet.field = field
	add_child_autofree(magnet)
	magnet.apply(1.0)
	assert_true(near.attracted)
	assert_true(far.attracted, "esté donde esté")


func test_the_bomb_hits_only_nearby_enemies() -> void:
	var center := Node3D.new()
	add_child_autofree(center)
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	var near := swarm.spawn(SWARMER, Vector3(5.0, 0.0, 0.0))
	var far := swarm.spawn(SWARMER, Vector3(40.0, 0.0, 0.0))
	var bomb := BombEffect.new()
	bomb.reward = &"bomb"
	bomb.swarm = swarm
	bomb.center = center
	bomb.radius = 15.0
	add_child_autofree(bomb)
	bomb.apply(1.0)
	assert_true(near.health.is_dead(), "a 5 m, toda su vida")
	assert_false(far.health.is_dead(), "a 40 m, fuera de su alcance")


func test_the_energy_drink_boosts_stats_for_a_while() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var drink := BuffEffect.new()
	drink.reward = &"energy"
	drink.stats = player.stats
	drink.buff = ENERGY_BUFF
	add_child_autofree(drink)
	var speed := player.stats.get_value(&"run_speed")
	EventBus.pickup_collected.emit(&"energy", 0.3)
	assert_gt(player.stats.get_value(&"run_speed"), speed)
	EventBus.pickup_collected.emit(&"energy", 0.3)
	var boosted := player.stats.get_value(&"run_speed")
	assert_almost_eq(boosted, speed * 1.25, 0.01, "otra lata no lo acumula")
	await wait_seconds(0.5)
	assert_false(drink.is_active())
	assert_eq(player.stats.get_value(&"run_speed"), speed, "se pasa el efecto")


func test_a_free_upgrade_levels_up_something_owned() -> void:
	var player := PlayerScene.instantiate() as Player
	player.character = preload("res://data/characters/warrior.tres")
	add_child_autofree(player)
	var upgrade := UpgradeEffect.new()
	upgrade.reward = &"upgrade"
	upgrade.weapons = player.weapons
	upgrade.runes = player.runes
	upgrade.rarities = preload("res://data/rarities/rarities.tres")
	add_child_autofree(upgrade)
	var sword := player.weapons.get_weapons()[0]
	upgrade.apply(2.0)
	assert_eq(sword.level, 3, "lo único que lleva es la espada: sube dos niveles")
	upgrade.apply(99.0)
	assert_eq(sword.level, sword.data.max_level(), "nunca pasa del máximo")


func test_the_elite_wave_brings_elites() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)
	var target := Node3D.new()
	add_child_autofree(target)
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	var director := WaveDirector.new()
	director.data = preload("res://data/waves/brosque.tres")
	director.swarm = swarm
	director.target = target
	add_child_autofree(director)
	await wait_physics_frames(2)
	var wave := EliteWaveEffect.new()
	wave.reward = &"elite_wave"
	wave.director = director
	add_child_autofree(wave)
	wave.apply(3.0)
	assert_eq(swarm.active_count(), 3)
	for enemy: Enemy in swarm.get_active():
		assert_true(enemy.is_elite())
