extends GutTest
## Mal de ojo (el arma del Brujo) con física real contra muñecos: persigue a su objetivo aunque se
## mueva, rebota a los siguientes con todo su daño y, si hace crítico, revienta y daña a los de
## alrededor (con un radio que crece con el área); sin crítico, no revienta.

const EVIL_EYE := preload("res://data/weapons/evil_eye.tres")
const ORB_SCENE := preload("res://systems/combat/weapons/evil_eye/evil_eye_orb.tscn")
const DummyScene := preload("res://entities/enemies/target_dummy/target_dummy.tscn")

var _offense: OffenseData
var _wielder: StatsComponent
var _inventory: WeaponInventory


func before_each() -> void:
	_offense = OffenseData.new()
	_offense.damage = 100.0
	_offense.crit_chance = 0.0
	_offense.crit_damage = 150.0
	_offense.attack_speed = 100.0
	_offense.projectile_speed = 100.0
	_offense.area = 100.0
	_offense.duration = 100.0
	_offense.knockback = 100.0
	_wielder = StatsComponent.new()
	_wielder.sources.append(_offense)
	add_child_autofree(_wielder)
	_inventory = WeaponInventory.new()
	_inventory.wielder_stats = _wielder
	add_child_autofree(_inventory)


func test_it_bounces_to_the_next_enemies() -> void:
	var first := _dummy_health(Vector3(0.0, 0.0, -7.0))
	var second := _dummy_health(Vector3(3.0, 0.0, -8.0))
	var third := _dummy_health(Vector3(6.0, 0.0, -7.0))
	_inventory.add(EVIL_EYE)
	await wait_physics_frames(90)
	assert_signal_emitted(first, "damaged")
	assert_signal_emitted(second, "damaged", "primer rebote")
	assert_signal_emitted(third, "damaged", "segundo rebote")


func test_it_chases_a_target_that_moves() -> void:
	var dummy := DummyScene.instantiate() as Node3D
	dummy.position = Vector3(0.0, 0.0, -9.0)
	add_child_autofree(dummy)
	var health := dummy.get_node(^"Health") as HealthComponent
	watch_signals(health)
	_inventory.add(EVIL_EYE)
	# En cuanto sale, el muñeco se aparta: un proyectil recto fallaría.
	await wait_physics_frames(3)
	dummy.position = Vector3(4.0, 0.0, -9.0)
	await wait_physics_frames(90)
	assert_signal_emitted(health, "damaged", "lo persigue")


func test_a_crit_bursts_on_the_ones_around() -> void:
	_wielder.add_modifier(StatModifier.create(&"crit_chance", StatModifier.Kind.FLAT, 100.0), self)
	var target := _dummy_health(Vector3(0.0, 0.0, -7.0))
	var beside := _dummy_health(Vector3(1.2, 0.0, -7.4))
	var far := _dummy_health(Vector3(-12.0, 0.0, -7.0))
	var weapon := _inventory.add(EVIL_EYE)
	weapon.stats.add_modifier(StatModifier.create(&"bounces", StatModifier.Kind.FLAT, -2.0), self)
	await wait_physics_frames(60)
	assert_signal_emitted(target, "damaged")
	assert_signal_emitted(beside, "damaged", "la explosión del crítico")
	assert_signal_not_emitted(far, "damaged", "fuera del radio")


func test_without_a_crit_it_does_not_burst() -> void:
	var target := _dummy_health(Vector3(0.0, 0.0, -7.0))
	var beside := _dummy_health(Vector3(1.2, 0.0, -7.4))
	var weapon := _inventory.add(EVIL_EYE)
	weapon.stats.add_modifier(StatModifier.create(&"bounces", StatModifier.Kind.FLAT, -2.0), self)
	await wait_physics_frames(60)
	assert_signal_emitted(target, "damaged")
	assert_signal_not_emitted(beside, "damaged", "sin crítico no revienta")


func test_the_burst_grows_with_area() -> void:
	var weapon := _inventory.add(EVIL_EYE) as ProjectileWeapon
	var projectile := ORB_SCENE.instantiate() as EvilEyeOrb
	add_child_autofree(projectile)
	projectile.weapon = weapon
	var base := projectile.explosion_radius()
	_wielder.add_modifier(StatModifier.create(&"area", StatModifier.Kind.PERCENT, 0.5), self)
	assert_almost_eq(projectile.explosion_radius(), base * 1.5, 0.01)


func _dummy_health(at: Vector3) -> HealthComponent:
	var dummy := DummyScene.instantiate() as Node3D
	dummy.position = at
	add_child_autofree(dummy)
	var health := dummy.get_node(^"Health") as HealthComponent
	watch_signals(health)
	return health
