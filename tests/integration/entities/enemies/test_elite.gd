extends GutTest
## Élites: un enemigo ascendido lleva las mejoras de EliteData (vida, daño al tocar y de sus armas,
## experiencia y oro), es más grande (cuerpo, zonas de golpe y modelo) y brilla; al volver a salir
## del pool es normal otra vez. boost() mejora sin cambiar el aspecto.

const SWARMER := preload("res://data/enemies/swarmer.tres")
const SHOOTER := preload("res://data/enemies/shooter.tres")
const ELITE := preload("res://data/enemies/elite.tres")

var _swarm: EnemySwarm


func before_each() -> void:
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)


func test_an_elite_is_tougher_and_drops_more() -> void:
	var normal := _swarm.spawn(SWARMER, Vector3(-5.0, 0.0, 0.0))
	var elite := _swarm.spawn(SWARMER, Vector3(5.0, 0.0, 0.0))
	elite.promote(ELITE)
	assert_true(elite.is_elite())
	assert_false(normal.is_elite())
	assert_eq(elite.health.get_maximum(), normal.health.get_maximum() * _multiplier(&"max_health"))
	assert_eq(elite.health.get_current(), elite.health.get_maximum(), "con la vida llena")
	assert_eq(elite.xp_reward(), normal.xp_reward() * _multiplier(&"xp_reward"))
	assert_eq(elite.gold_reward(), normal.gold_reward() * _multiplier(&"gold_reward"))
	assert_eq(elite.contact_hitbox.base_damage, normal.contact_hitbox.base_damage * _multiplier(&"contact_damage"))


func test_an_elite_is_bigger_and_glows() -> void:
	var normal := _swarm.spawn(SWARMER, Vector3(-5.0, 0.0, 0.0))
	var elite := _swarm.spawn(SWARMER, Vector3(5.0, 0.0, 0.0))
	elite.promote(ELITE)
	await _appeared(elite)
	assert_almost_eq(elite.visual.scale.x, normal.visual.scale.x * ELITE.size, 1e-4, "modelo")
	var normal_hurtbox := _first_shape(normal.hurtbox)
	var elite_hurtbox := _first_shape(elite.hurtbox)
	assert_almost_eq(elite_hurtbox.scale.x, normal_hurtbox.scale.x * ELITE.size, 1e-4, "zona de golpe")
	assert_almost_eq(elite_hurtbox.position.y, normal_hurtbox.position.y * ELITE.size, 1e-4, "y sigue en el suelo")
	assert_almost_eq(elite.mass, normal.mass * pow(ELITE.size, 3.0), 1e-3, "más pesado")
	var mesh := elite.visual.get_child(0) as GeometryInstance3D
	assert_same(mesh.material_overlay, ELITE.overlay, "brilla")


func test_elite_weapons_hit_harder() -> void:
	var normal := _swarm.spawn(SHOOTER, Vector3(-5.0, 0.0, 0.0))
	var elite := _swarm.spawn(SHOOTER, Vector3(5.0, 0.0, 0.0))
	elite.promote(ELITE)
	var normal_damage := normal.weapons.get_weapons()[0].damage()
	assert_eq(elite.weapons.get_weapons()[0].damage(), normal_damage * _multiplier(&"damage"))


func test_back_from_the_pool_it_is_normal_again() -> void:
	var elite := _swarm.spawn(SWARMER, Vector3.ZERO)
	var normal_health := elite.health.get_maximum()
	await _appeared(elite)
	var normal_scale := elite.visual.scale
	elite.promote(ELITE)
	elite.health.take_damage(DamageInfo.create(100000.0))
	await wait_physics_frames(20)
	var again := _swarm.spawn(SWARMER, Vector3.ZERO)
	assert_same(again, elite, "el mismo, reutilizado")
	await _appeared(again)
	assert_false(again.is_elite())
	assert_eq(again.health.get_maximum(), normal_health)
	assert_eq(again.visual.scale, normal_scale)
	assert_null((again.visual.get_child(0) as GeometryInstance3D).material_overlay)


func test_boost_changes_stats_but_not_the_look() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	var normal_health := enemy.health.get_maximum()
	await _appeared(enemy)
	var normal_scale := enemy.visual.scale
	var modifiers := StatModifierSet.new()
	modifiers.stat_modifiers.append(StatModifier.create(&"max_health", StatModifier.Kind.MULTIPLIER, 2.0))
	enemy.boost(modifiers)
	assert_eq(enemy.health.get_maximum(), normal_health * 2.0)
	assert_eq(enemy.health.get_current(), enemy.health.get_maximum())
	assert_eq(enemy.visual.scale, normal_scale)
	assert_false(enemy.is_elite())


## Espera a que [param enemy] termine de salir del suelo (mientras sale, su modelo crece).
func _appeared(enemy: Enemy) -> void:
	await wait_seconds(enemy.appear_time + 0.05)


## Multiplicador de élite de [param stat] (1 si no lo cambia).
func _multiplier(stat: StringName) -> float:
	for modifier: StatModifier in ELITE.stat_modifiers.stat_modifiers:
		if modifier.stat == stat and modifier.kind == StatModifier.Kind.MULTIPLIER:
			return modifier.value
	return 1.0


func _first_shape(area: Area3D) -> CollisionShape3D:
	for child: Node in area.get_children():
		if child is CollisionShape3D:
			return child as CollisionShape3D
	return null
