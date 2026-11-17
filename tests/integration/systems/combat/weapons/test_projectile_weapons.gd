extends GutTest
## Bastón y daga con física real contra muñecos: el orbe explota y daña a todos en su radio (y no
## más allá), también al chocar con una pared; la daga da a uno solo y, con rebotes, salta al
## siguiente con todo su daño.

const STAFF := preload("res://data/weapons/staff.tres")
const DAGGER := preload("res://data/weapons/dagger.tres")
const DummyScene := preload("res://entities/enemies/target_dummy/target_dummy.tscn")

var _inventory: WeaponInventory


func before_each() -> void:
	var offense := OffenseData.new()
	offense.damage = 100.0
	offense.crit_damage = 150.0
	offense.attack_speed = 100.0
	offense.projectile_speed = 100.0
	offense.area = 100.0
	offense.duration = 100.0
	offense.knockback = 100.0
	var wielder := StatsComponent.new()
	wielder.sources.append(offense)
	add_child_autofree(wielder)
	_inventory = WeaponInventory.new()
	_inventory.wielder_stats = wielder
	add_child_autofree(_inventory)


func test_staff_orb_hits_everyone_in_the_blast() -> void:
	var target := _dummy_health(Vector3(0.0, 0.0, -6.0))
	var beside := _dummy_health(Vector3(1.3, 0.0, -6.6))
	var far := _dummy_health(Vector3(7.0, 0.0, -6.0))
	_inventory.add(STAFF)
	await wait_physics_frames(40)
	assert_signal_emitted(target, "damaged")
	assert_signal_emitted(beside, "damaged", "dentro del radio")
	assert_signal_not_emitted(far, "damaged", "fuera del radio")


func test_staff_orb_explodes_on_walls() -> void:
	_add_wall(Vector3(0.0, 1.0, -3.0))
	var behind := _dummy_health(Vector3(0.0, 0.0, -7.0))
	_inventory.add(STAFF)
	await wait_physics_frames(40)
	assert_signal_not_emitted(behind, "damaged", "la pared lo para y explota lejos")


func test_dagger_hits_a_single_enemy() -> void:
	var target := _dummy_health(Vector3(0.0, 0.0, -8.0))
	var other := _dummy_health(Vector3(2.0, 0.0, -8.5))
	_inventory.add(DAGGER)
	await wait_physics_frames(20)
	assert_signal_emitted(target, "damaged")
	assert_signal_not_emitted(other, "damaged", "sin rebotes")


func test_dagger_bounces_to_the_next_enemy() -> void:
	var target := _dummy_health(Vector3(0.0, 0.0, -8.0))
	var other := _dummy_health(Vector3(2.0, 0.0, -9.0))
	_inventory.add(DAGGER).set_level(2)
	await wait_physics_frames(40)
	assert_signal_emitted(target, "damaged")
	assert_signal_emitted(other, "damaged", "rebota con todo su daño")


func test_disarming_recalls_its_projectiles_in_flight() -> void:
	var target := _dummy_health(Vector3(0.0, 0.0, -8.0))
	var staff := _inventory.add(STAFF)
	watch_signals(staff)
	await wait_physics_frames(2)
	assert_signal_emitted(staff, "fired")
	staff.disarm()
	await wait_physics_frames(60)
	assert_signal_not_emitted(target, "damaged", "el orbe desapareció")
	assert_signal_emit_count(staff, "fired", 1, "y no ataca más")


func test_rearming_waits_before_attacking() -> void:
	_dummy_health(Vector3(0.0, 0.0, -6.0))
	var dagger := _inventory.add(DAGGER)
	dagger.disarm()
	dagger.rearm(0.5)
	watch_signals(dagger)
	await wait_physics_frames(15)
	assert_signal_not_emitted(dagger, "fired")
	await wait_physics_frames(30)
	assert_signal_emitted(dagger, "fired")


func _dummy_health(at: Vector3) -> HealthComponent:
	var dummy := DummyScene.instantiate() as Node3D
	dummy.position = at
	add_child_autofree(dummy)
	var health := dummy.get_node(^"Health") as HealthComponent
	watch_signals(health)
	return health


func _add_wall(at: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	wall.position = at
	var box := BoxShape3D.new()
	box.size = Vector3(8.0, 4.0, 0.5)
	var shape := CollisionShape3D.new()
	shape.shape = box
	wall.add_child(shape)
	add_child_autofree(wall)
