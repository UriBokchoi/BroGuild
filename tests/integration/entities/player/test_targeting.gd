extends GutTest
## Apuntar y fijar: de serie las armas van a lo más cercano; apuntando, a lo más cercano a la mira;
## con un jefe fijado, a él mientras esté a su alcance. Al morir el jefe se suelta. La mira del HUD y
## la marca del fijado se ven cuando toca.

const SWARMER := preload("res://data/enemies/swarmer.tres")
const TROLL := preload("res://data/enemies/trolleador.tres")
const STAFF := preload("res://data/weapons/staff.tres")
const MarkerScene := preload("res://vfx/juice/lock_marker/lock_marker.tscn")

var _swarm: EnemySwarm
var _targeting: Targeting
var _inventory: WeaponInventory
var _body: Node3D


func before_each() -> void:
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)
	_body = Node3D.new()
	add_child_autofree(_body)
	_targeting = Targeting.new()
	_targeting.body = _body
	add_child_autofree(_targeting)
	var offense := OffenseData.new()
	offense.damage = 100.0
	offense.attack_speed = 100.0
	offense.projectile_speed = 100.0
	offense.area = 100.0
	offense.duration = 100.0
	var stats := StatsComponent.new()
	stats.sources.append(offense)
	add_child_autofree(stats)
	_inventory = WeaponInventory.new()
	_inventory.wielder_stats = stats
	_inventory.targeting = _targeting
	add_child_autofree(_inventory)


func test_by_default_the_nearest() -> void:
	var near := _swarm.spawn(SWARMER, Vector3(3.0, 0.0, 0.0))
	_swarm.spawn(SWARMER, Vector3(-8.0, 0.0, 0.0))
	await wait_physics_frames(2)
	assert_eq(_first_target(), near.hurtbox)


func test_aiming_goes_for_what_the_crosshair_points_at() -> void:
	_swarm.spawn(SWARMER, Vector3(3.0, 0.0, 0.0))
	var far := _swarm.spawn(SWARMER, Vector3(-8.0, 0.0, 0.0))
	await wait_physics_frames(2)
	_targeting.set("_aiming", true)
	_targeting.set("_aim_point", Vector3(-8.0, 1.0, 0.0))
	assert_eq(_first_target(), far.hurtbox, "el de la mira, aunque esté más lejos")


func test_a_locked_boss_takes_every_shot_and_is_released_when_it_dies() -> void:
	_swarm.spawn(SWARMER, Vector3(2.0, 0.0, 0.0))
	var boss := _swarm.spawn(TROLL, Vector3(-9.0, 0.0, 0.0))
	await wait_physics_frames(2)
	watch_signals(EventBus)
	_targeting.toggle_lock()
	assert_same(_targeting.get_locked(), boss.hurtbox)
	assert_signal_emitted_with_parameters(EventBus, "target_locked", [boss])
	assert_eq(_first_target(), boss.hurtbox, "al fijado, aunque haya otro más cerca")
	boss.health.take_damage(DamageInfo.create(1.0e9))
	await wait_physics_frames(2)
	assert_null(_targeting.get_locked(), "muerto, se suelta")


func test_locking_again_releases() -> void:
	_swarm.spawn(TROLL, Vector3(-5.0, 0.0, 0.0))
	await wait_physics_frames(1)
	_targeting.toggle_lock()
	assert_not_null(_targeting.get_locked())
	_targeting.toggle_lock()
	assert_null(_targeting.get_locked())


func test_without_a_boss_nothing_is_locked() -> void:
	_swarm.spawn(SWARMER, Vector3(2.0, 0.0, 0.0))
	_targeting.toggle_lock()
	assert_null(_targeting.get_locked())


func test_the_marker_follows_the_locked_one() -> void:
	var marker := MarkerScene.instantiate() as LockMarker
	add_child_autofree(marker)
	var boss := _swarm.spawn(TROLL, Vector3(-5.0, 0.0, 0.0))
	await wait_physics_frames(1)
	_targeting.toggle_lock()
	assert_true(marker.is_following(boss))
	await wait_process_frames(2)
	assert_gt(marker.global_position.y, boss.global_position.y + 1.0, "encima de su cabeza")
	_targeting.toggle_lock()
	assert_false(marker.visible)


func test_the_crosshair_shows_while_aiming() -> void:
	var crosshair := Crosshair.new()
	add_child_autofree(crosshair)
	assert_false(crosshair.visible)
	EventBus.aim_changed.emit(true)
	assert_true(crosshair.visible)
	EventBus.aim_changed.emit(false)
	assert_false(crosshair.visible)


## El primer objetivo que elegiría el bastón (va a lo más cercano y se ve desde lejos).
func _first_target() -> Node3D:
	var weapon := _inventory.add(STAFF)
	var targets: Array[Node3D] = weapon.call(&"_find_targets")
	_inventory.remove(STAFF)
	return targets[0] if not targets.is_empty() else null
